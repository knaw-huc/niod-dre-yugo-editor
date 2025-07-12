<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:err="http://www.w3.org/2005/xqt-errors" 
                xmlns:clariah="http://www.clariah.eu/"
                exclude-result-prefixes="clariah err"
                version="3.0">
    
    <xsl:output method="xml" omit-xml-declaration="yes"/>
    
    <xsl:param name="cwd" select="'file:/Users/menzowi/Documents/Projects/huc-cmdi-editor/service/'"/>
    <xsl:param name="base" select="'http://localhost:1210'"/>
    <xsl:param name="app" select="'adoptie'"/>
    <xsl:param name="nr" select="'1'"/>
    <xsl:param name="config" select="doc(concat($cwd, '/data/apps/', $app, '/config.xml'))"/>
    <xsl:param name="prof" select="$config/config/app/def_prof"/>
    
    
    <xsl:param name="style" select="'style.css'"/>
    <xsl:param name="tweak-uri" select="''"/>
    <xsl:param name="tweak-doc" select="document($tweak-uri)"/>
    
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
        
    <xsl:template match="text()"/>
    
    <xsl:template name="title">
        <!--<xsl:comment expand-text="yes">
             prof[{$prof}]
             xpath[{$config/config/app/prof/*[prof=$prof]/title}]
             </xsl:comment>-->
        <xsl:variable name="xpath" select="$config/config/app/prof/*[prof=$prof]/title"/>
        <xsl:try>
            <xsl:evaluate xpath="$xpath" context-item="." namespace-context="$NS"/>
            <xsl:catch>
                <span class="err" expand-text="yes">ERR[{$err:code}]: {$err:description}</span>
            </xsl:catch>
        </xsl:try>
    </xsl:template>
    
    <xsl:template match="/">
        <div class="body">
            <h1>
                <xsl:call-template name="title"/>
            </h1>
            <dl>
                <xsl:apply-templates select="/*:CMD/*:Components/*">
                    <xsl:with-param name="tweak" select="$tweak-doc/ComponentSpec"/>
                </xsl:apply-templates>
            </dl>
        </div>
    </xsl:template>
    
    <xsl:template match="*:IdentifierExternal/*:uri">
        <xsl:param name="tweak"/>
        <xsl:variable name="t" select="$tweak/*[@name=local-name(current())]"/>
        <dt class="{local-name()} level-{count(ancestor::*) - 1} {local-name($t)}">
            <xsl:choose>
                <xsl:when test="normalize-space($t/clariah:label)!=''">
                    <xsl:value-of select="normalize-space($t/clariah:label)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="local-name()"/>
                </xsl:otherwise>
            </xsl:choose>
        </dt>
        <dd class="{local-name()} level-{count(ancestor::*) - 1} {local-name($t)}">
            <xsl:choose>
                <xsl:when test="matches(.,'http(s)?://')">
                    <a href="{.}" target="external">
                        <xsl:value-of select="."/>
                    </a>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="."/>
                </xsl:otherwise>
            </xsl:choose>
        </dd>
    </xsl:template>
    
    <xsl:template match="*">
        <xsl:param name="tweak"/>
        <xsl:variable name="t" select="$tweak/*[@name=local-name(current())]"/>
        <dt class="{local-name()} level-{count(ancestor::*) - 1} {local-name($t)}">
            <xsl:choose>
                <xsl:when test="normalize-space($t/clariah:label)!=''">
                    <xsl:value-of select="normalize-space($t/clariah:label)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="local-name()"/>
                </xsl:otherwise>
            </xsl:choose>
        </dt>
        <dd class="{local-name()} level-{count(ancestor::*) - 1} {local-name($t)}">
            <xsl:choose>
                <xsl:when test="*">
                    <dl>
                        <xsl:apply-templates>
                            <xsl:with-param name="tweak" select="$t"/>
                        </xsl:apply-templates>
                    </dl>
                </xsl:when>
                <xsl:when test="normalize-space(@*:valueConceptLink)!=''">
                    <xsl:choose>
                        <xsl:when test="matches(@*:valueConceptLink,'/entity/([^/]+)/([0-9]+)$')">
                            <xsl:variable name="rec" select="replace(@*:valueConceptLink,'.*/entity/[^/]+/([0-9]+)$','$1')"/>
                            <xsl:variable name="ent" select="replace(@*:valueConceptLink,'.*/entity/([^/]+)/[0-9]+$','$1')"/>
                            <a href="/{$ent}_detail/{$rec}">
                                <xsl:value-of select="."/>
                            </a>
                        </xsl:when>
                        <xsl:when test="matches(@*:valueConceptLink,'^ref:/')">
                            <a href="{normalize-space(replace(@*:valueConceptLink,'^ref:/','/'))}">
                                <xsl:value-of select="."/>
                            </a>
                        </xsl:when>
                        <xsl:otherwise>
                            <a href="{normalize-space(@*:valueConceptLink)}" target="conceptlink">
                                <xsl:value-of select="."/>
                            </a>                            
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="."/>
                </xsl:otherwise>
            </xsl:choose>
        </dd>
    </xsl:template>        
    
</xsl:stylesheet>