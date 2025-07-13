<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:math="http://www.w3.org/2005/xpath-functions/math"
    xmlns:err="http://www.w3.org/2005/xqt-errors" 
    xmlns:cmd="http://www.clarin.eu/cmd/1"
    xmlns:yugo="http://yugo.niod.nl/"
    exclude-result-prefixes="xs math cmd err"
    version="3.0">
    
    <xsl:param name="cwd" select="'file:/Users/menzowi/Documents/GitHub/niod-dre-yugo-editor'"/>
    <xsl:param name="app" select="'yugo'"/>
    <xsl:param name="config" select="doc(concat($cwd, '/data/apps/', $app, '/config.xml'))"/>
       
    <xsl:template match="/">
        <xsl:call-template name="main"/>
    </xsl:template>
    
    <xsl:template name="main">
        <xsl:variable name="graph">
            <graph>
                <xsl:for-each select="$config/config/app/prof/*">
                    <xsl:variable name="p" select="."/>
                    <xsl:variable name="ent" select="local-name()"/>
                    <xsl:variable name="prof" select="prof"/>
                    <xsl:message expand-text="yes">DBG:ent[{$ent}]prof[{$prof}]</xsl:message>
                    <xsl:variable name="hooks" select="hooks"/>
                    <xsl:variable name="recs" select="concat($cwd, '/data/apps/', $app, '/profiles/', $prof, '/records')"/>
                    <xsl:for-each select="collection(concat($recs,'?match=record-\d+\.xml&amp;on-error=warning'))">
                        <xsl:message expand-text="yes">DBG:rec[{base-uri()}]</xsl:message>
                        <xsl:for-each select="//*:Relationship/*:to[normalize-space(@*:valueConceptLink)!='']">
                            <xsl:variable name="rel" select="normalize-space(@*:valueConceptLink)"/>
                            <xsl:variable name="title">
                                <xsl:variable name="cmd-ns" select="
                                    if ($config//app/cmdi_version = '1.2')  then
                                    'http://www.clarin.eu/cmd/1'
                                    else
                                    'http://www.clarin.eu/cmd/'"/>
                                <xsl:variable name="cmdp-ns" select="
                                    if ($config//app/cmdi_version = '1.2')  then
                                    concat('http://www.clarin.eu/cmd/1/profiles/',$prof)
                                    else
                                    ()"/>              
                                <xsl:variable name="NS" as="element()">
                                    <xsl:element namespace="{$cmd-ns}" name="cmd:ns">
                                        <xsl:if test="exists($cmdp-ns)">
                                            <xsl:namespace name="cmdp" select="$cmdp-ns"/>
                                        </xsl:if>
                                    </xsl:element>
                                </xsl:variable>
                                <xsl:variable name="xpath" select="$config/config/app/prof/*[prof=$prof]/title"/>
                                <xsl:try>
                                    <xsl:evaluate xpath="$xpath" context-item="." namespace-context="$NS"/>
                                    <xsl:catch>
                                        <xsl:text expand-text="yes">ERR[{$err:code}]: {$err:description}</xsl:text>
                                    </xsl:catch>
                                </xsl:try>
                            </xsl:variable>
                            <edge>
                                <xsl:if test="normalize-space(../*:category)!=''">
                                    <xsl:attribute name="category" select="normalize-space(../*:category)"/>
                                </xsl:if>
                                <from id="{replace(//cmd:MdSelfLink,'unl://','')}" ent="{$ent}" prof="{//cmd:MdProfile}" title="{$title}"/>
                                <!-- ref:/app/yugo/profile/clarin.eu:cr1:p_1721373443955/entity/person/1 -->
                                <xsl:variable name="re" select="'ref:/.*/profile/([^/]+)/entity/([^/]+)/([0-9]+)'"/>
                                <to id="{replace($rel,$re,'$3')}" ent="{replace($rel,$re,'$2')}" prof="{replace($rel,$re,'$1')}" title="{.}"/>
                            </edge>
                        </xsl:for-each>
                    </xsl:for-each>
                </xsl:for-each>
            </graph>
        </xsl:variable>
        <xsl:variable name="collectionHierarchy">
            <collectionHierarchy>
                <xsl:for-each select="$graph//to[@ent='institution']">
                    <xsl:variable name="i" select="."/>
                    <institution>
                        <xsl:copy-of select="$i/@*"/>
                        <xsl:for-each select="$graph//*[child::to[@id=$i/@id][@ent='institution']]/from[@ent='collection']">
                            <xsl:call-template name="collectionHierarchy">
                                <xsl:with-param name="graph" select="$graph"/>
                            </xsl:call-template>
                        </xsl:for-each>
                    </institution>
                </xsl:for-each>
            </collectionHierarchy>
        </xsl:variable>
        <res>
            <xsl:copy-of select="$graph"/>
            <xsl:copy-of select="$collectionHierarchy"/>
        </res>
    </xsl:template>
    
    <xsl:template name="collectionHierarchy">
        <xsl:param name="graph"/>
        <xsl:variable name="c" select="."/>
        <collection>
            <xsl:copy-of select="$c/@*"/>
            <xsl:for-each select="$graph//*[child::to[@id=$c/@id][@ent='collection']]/from[@ent='collection']">
                <xsl:call-template name="collectionHierarchy">
                    <xsl:with-param name="graph" select="$graph"/>
                </xsl:call-template>
            </xsl:for-each>
        </collection>
    </xsl:template>
   
   
</xsl:stylesheet>