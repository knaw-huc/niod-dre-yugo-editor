from saxonche import PySaxonProcessor, PyXdmNode
from src.profiles import prof_xml
from fastapi import Request, Response, HTTPException
import toml
import os
import logging
from src.commons import settings, convert_toml_to_xml
from apps.yugo.src.read_and_index import read_and_index


def browser(req:Request, action:str, app: str, prof: str, nr: str, user:str) -> None:
    res = "This will be the response"
    with PySaxonProcessor(license=False) as proc:
        xpproc = proc.new_xpath_processor()
        xpproc.set_cwd(os.getcwd())
        xsltproc = proc.new_xslt30_processor()
        xsltproc.set_cwd(os.getcwd())
        executable = xsltproc.compile_stylesheet(stylesheet_file=f"{settings.URL_DATA_APPS}/{app}/resources/xslt/toBrowser.xsl")
        executable.set_parameter("cwd", proc.make_string_value(os.getcwd()))
        executable.set_parameter("base", proc.make_string_value(settings.url_base))
        executable.set_parameter("app", proc.make_string_value(app))
        executable.set_parameter("prof", proc.make_string_value(prof))
        executable.set_parameter("nr", proc.make_string_value(nr))
        graph = to_graph(app)
        graph = proc.parse_xml(xml_text=graph)
        executable.set_parameter("graph", graph)
        tweak = prof_xml(app, prof)
        tweak = proc.parse_xml(xml_text=tweak)
        executable.set_parameter("tweak-doc",tweak)
        config_app_file = f"{settings.URL_DATA_APPS}/{app}/config.toml"
        convert_toml_to_xml(toml_file=config_app_file,xml_file=f"{settings.URL_DATA_APPS}/{app}/config.xml")
        config = proc.parse_xml(xml_file_name=f"{settings.URL_DATA_APPS}/{app}/config.xml")
        executable.set_parameter("config", config)
        record_file = f"{settings.URL_DATA_APPS}/{app}/profiles/{prof}/records/record-{nr}.xml"
        with open(record_file, 'r') as file:
            rec = file.read()
            rec = proc.parse_xml(xml_text=rec)
            res = executable.transform_to_string(xdm_node=rec)
    return Response(content=res, media_type="text/html")

def graph(req:Request, action:str, app: str, prof: str, nr: str, user:str) -> None:
    res = "This will be the response"
    res = to_graph(app)
    return Response(content=res, media_type="application/xml")

def to_graph(app: str):
    with PySaxonProcessor(license=False) as proc:
        xpproc = proc.new_xpath_processor()
        xpproc.set_cwd(os.getcwd())
        xsltproc = proc.new_xslt30_processor()
        xsltproc.set_cwd(os.getcwd())
        executable = xsltproc.compile_stylesheet(stylesheet_file=f"{settings.URL_DATA_APPS}/{app}/resources/xslt/toGraph.xsl")
        executable.set_parameter("cwd", proc.make_string_value(os.getcwd()))
        executable.set_parameter("app", proc.make_string_value(app))
        config_app_file = f"{settings.URL_DATA_APPS}/{app}/config.toml"
        convert_toml_to_xml(toml_file=config_app_file,xml_file=f"{settings.URL_DATA_APPS}/{app}/config.xml")
        config = proc.parse_xml(xml_file_name=f"{settings.URL_DATA_APPS}/{app}/config.xml")
        executable.set_parameter("config", config)
        null = proc.parse_xml(xml_text="<null/>")
        return executable.transform_to_string(xdm_node=null)
    
def indexer(req:Request, action:str, app: str, prof: str, nr: str, user:str) -> None:
        graph = to_graph(app)
        with open(f"{settings.URL_DATA_APPS}/{app}/graph.xml", 'w', encoding='utf-8') as f:
            f.write(graph)

        res = "indexed:"
        if prof == None or prof=='clarin.eu:cr1:p_1721373443934':
            read_and_index(toml_file=f"{settings.URL_DATA_APPS}/{app}/indexes/institution.toml",input_dir=f"{settings.URL_DATA_APPS}/{app}/profiles/clarin.eu:cr1:p_1721373443934/records")
            res=res + " institutions"
        if prof == None or prof=='clarin.eu:cr1:p_1747312582429':
            read_and_index(toml_file=f"{settings.URL_DATA_APPS}/{app}/indexes/collection.toml",input_dir=f"{settings.URL_DATA_APPS}/{app}/profiles/clarin.eu:cr1:p_1747312582429/records")
            res=res + " collections"
        if prof == None or prof=='clarin.eu:cr1:p_1721373443955':
            read_and_index(toml_file=f"{settings.URL_DATA_APPS}/{app}/indexes/person.toml",input_dir=f"{settings.URL_DATA_APPS}/{app}/profiles/clarin.eu:cr1:p_1721373443955/records")
            res=res + " persons"
        if prof == None or prof=='clarin.eu:cr1:p_1747312582450':
            read_and_index(toml_file=f"{settings.URL_DATA_APPS}/{app}/indexes/group.toml",input_dir=f"{settings.URL_DATA_APPS}/{app}/profiles/clarin.eu:cr1:p_1747312582450/records")
            res=res + " groups"
        if prof == None or prof=='clarin.eu:cr1:p_1744616237113':
            read_and_index(toml_file=f"{settings.URL_DATA_APPS}/{app}/indexes/place.toml",input_dir=f"{settings.URL_DATA_APPS}/{app}/profiles/clarin.eu:cr1:p_1744616237113/records")
            res=res + " places"
        if prof == None or prof=='clarin.eu:cr1:p_1733830015132':
            read_and_index(toml_file=f"{settings.URL_DATA_APPS}/{app}/indexes/event.toml",input_dir=f"{settings.URL_DATA_APPS}/{app}//profiles/clarin.eu:cr1:p_1733830015132/records")
            res=res + " events"
        return res
