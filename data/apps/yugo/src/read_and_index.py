# -*- coding: utf-8 -*-
import argparse
from datetime import datetime
from elasticsearch import Elasticsearch
from elasticsearch.helpers import bulk
import locale
#locale.setlocale(locale.LC_ALL, 'nl_NL')
import sys
import os
import glob
import json
from saxonche import PySaxonProcessor
import tomllib


class Indexer:
    es: Elasticsearch = None
    config: dict
    index_name: str

    def __init__(self, es: Elasticsearch, config: dict, index_name: str):
        self.es = es
        self.config = config
        self.index_name = index_name

    def parse_xml(self, infile: str) -> dict:
        """
        Process an input XML file according to config and return resulting dict.
        :param infile:
        :return:
        """
        '''
        when = xpproc.evaluate_single("string((/*:CMD/*:Header/*:MdCreationDate/@clariah:epoch,/*:CMD/*:Header/*:MdCreationDate,'unknown')[1])").get_string_value()
        '''
        with PySaxonProcessor(license=False) as proc:
            doc = None
            xpproc = proc.new_xpath_processor()
            node = proc.parse_xml(xml_text=infile)
            xpproc.set_context(xdm_item=node)
            for key in self.config['index']['input']['ns'].keys():
                xpproc.declare_namespace(key,self.config['index']['input']['ns'][key])
            do = True
            if 'when' in self.config['index']['input'].keys():
                do = xpproc.effective_boolean_value(f"{self.config['index']['input']['when']}")
            if do:
                path_id = self.config['index']['id']['path']
                doc_id = xpproc.evaluate_single(f"{path_id}").get_string_value() 
                doc = {'id': doc_id}
                xpproc.declare_variable('id')
                xpproc.set_parameter('id',proc.make_string_value(doc_id))
                if self.config["index"]["full_text"]=="yes":
                    val = xpproc.evaluate_single("string-join(//cmd:Components//text()/normalize-space()[.!=''],' ')")
                    if val:
                        doc["full_text"] = val.get_string_value()
                for key in self.config['index']['facet'].keys():
                    facet = self.config["index"]["facet"][key]
                    stderr(f"FACET[{key}]")
                    path_facet = facet["path"]
                    cardinality="list"
                    if ('cardinality' in facet.keys()):
                        cardinality = facet['cardinality']
                    if cardinality == 'single':
                        val = xpproc.evaluate_single(f"{path_facet}")
                        if val:
                            val = val.get_string_value()
                            if val.strip() != '':
                                doc[key] = val
                    else:
                        res = []
                        items = xpproc.evaluate(f"{path_facet}")
                        if items:
                            for item in xpproc.evaluate(f"{path_facet}"):
                                val = item.get_string_value()
                                if val.strip() != '':
                                    res.append(val)
                            doc[key] = res
            return doc

    def create_mapping(self, overwrite: bool = False) -> dict:
        """
        Create the elasticsearch index mapping according to config and return resulting dict.
        :return:
        """
        if overwrite:
            self.es.indices.delete(index=self.index_name, ignore=[400, 404])

        properties = {}
        for facet_name in self.config['index']['facet'].keys():
            if self.config["index"]["full_text"]=="yes":
                properties["full_text"] = {
                    'type': 'text',
                    'fields': {
                        'keyword': {
                            'type': 'keyword'
                        },
                    }
                }
            facet = self.config["index"]["facet"][facet_name]
            type = facet.get('type', 'text')
            if type == 'text':
                properties[facet_name] = {
                    'type': 'text',
                    'fields': {
                        'keyword': {
                            'type': 'keyword',
                            'ignore_above': 256
                        },
                    }
                }
            elif type == 'keyword':
                properties[facet_name] = {
                    'type': 'keyword',
                }
            elif type == 'number':
                properties[facet_name] = {
                    'type': 'integer',
                }
            elif type == 'date':
                properties[facet_name] = {
                    'type': 'date',
                }

        mappings = {
            'properties': properties
        }

        settings = {
            'number_of_shards': 2,
            'number_of_replicas': 0
        }

        # misschien aanpassen naar create_if_not_exists
        self.es.indices.create(index=self.index_name, mappings=mappings, settings=settings)
        return mappings


    def import_files(self, files: list[str]):
        """
        Import files into an elasticsearch index based on the given config.
        :param files: list of files to import
        :param index: Elasticsearch index
        :return:
        """
        #es = Elasticsearch()
        actions = []
        self.extension = self.config['index']['input']['format']
        for inv in files:
            stderr(f"RECORD[{inv}]")
            doc = None
            with open(inv) as f:
                if self.extension=='xml':
                    d = f.read()
                    doc = self.parse_xml(d)
                else:
                    stderr(f'we don\'t do {extension} yet.')
                    continue
                if doc:
                    actions.append({'_index': self.index_name, '_id': doc['id'], '_source': doc})
        # add to index:
        stderr(json.dumps(actions))
        bulk(self.es, actions)


def stderr(text):
    sys.stderr.write("{}\n".format(text))


def read_and_index(toml_file: str, input_dir: str, index_name: str | None=None, index_host: str | None=None, force: bool | None=True):
    stderr(datetime.today().strftime("start: %H:%M:%S"))
    with open(toml_file, "rb") as f:
        config = tomllib.load(f)

    extension = config['index']['input']['format']
    stderr(f'extension: {extension}')
    input_list = glob.glob(f'{input_dir}/*.{extension}')

    index = "test"
    if 'name' in config['index']:
        index = config['index']['name']
    if index_name:
        index = index_name
    stderr(f"INDEX[{index}]")

    host = os.getenv("ES_URL", "http://localhost:9200/")
    if 'host' in config['index']:
        host = config['index']['host']
    if index_host:
        host = index_host
    stderr(f"HOST[{host}]")

    indexer = Indexer(Elasticsearch(hosts=host,verify_certs=False), config, index)

    indexer.create_mapping(overwrite=force)
    indexer.import_files(input_list)