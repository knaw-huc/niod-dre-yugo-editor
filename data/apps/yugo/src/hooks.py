from saxonche import PySaxonProcessor, PyXdmNode
from src.profiles import prof_xml
from fastapi import Response, HTTPException
import toml
import os
import logging
from src.commons import settings, convert_toml_to_xml

def browser(action:str, app: str, prof: str, nr: str, user:str) -> None:
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
