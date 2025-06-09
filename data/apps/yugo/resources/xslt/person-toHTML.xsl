<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:clariah="http://www.clariah.eu/" xmlns:cmd="http://www.clarin.eu/cmd/1"
    xmlns:cmdp="http://www.clarin.eu/cmd/1/profiles/clarin.eu:cr1:p_1721373443955"
    exclude-result-prefixes="clariah" version="3.0">

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
            if ($config//app/cmdi_version = '1.2') then
                'http://www.clarin.eu/cmd/1'
            else
                'http://www.clarin.eu/cmd/'"/>
    <xsl:variable name="cmdp-ns" select="
            if ($config//app/cmdi_version = '1.2') then
                concat('http://www.clarin.eu/cmd/1/profiles/', $prof)
            else
                ()"/>
    <xsl:variable name="NS" as="element()">
        <xsl:element namespace="{$cmd-ns}" name="cmd:ns">
            <xsl:if test="exists($cmdp-ns)">
                <xsl:namespace name="cmdp" select="$cmdp-ns"/>
            </xsl:if>
        </xsl:element>
    </xsl:variable>


    <xsl:output method="html"/>

    <xsl:template match="text()"/>

    <xsl:template name="title">
        <!--<xsl:comment expand-text="yes">
            prof[{$prof}]
            xpath[{$config/config/app/prof/*[prof=$prof]/title}]
        </xsl:comment>-->
        <xsl:variable name="xpath" select="$config/config/app/prof/*[prof = $prof]/title"/>
        <xsl:evaluate xpath="$xpath" context-item="." namespace-context="$NS"/>
    </xsl:template>
    
    <xsl:function name="clariah:toURL">
        <!-- ref:/app/yugo/profile/clarin.eu:cr1:p_1721373443955/entity/person/4 -->
        <xsl:param name="ref"/>
        <xsl:param name="ext"/>
        <!--http://localhost:1210/app/yugo/profile/clarin.eu:cr1:p_1721373443955/entity/person/4.xml -->
        <xsl:value-of select="replace(replace(replace($ref,'^ref:',$base),'^(.*)/profile/(.*)/entity/.*/([\p{N}]+)','$1/profile/$2/record/$3'),'(.+)$',concat('$1',$ext))"/>
    </xsl:function>

    <xsl:template match="/">
        <html>
            <head>
                <title>
                    <xsl:call-template name="title"/>
                </title>
                <link href="{$style}" rel="stylesheet"/>
            </head>
            <body>
                <table>
                    <tr>
                        <td colspan="2">
                            <h1>
                                <xsl:value-of
                                    select="//cmdp:CorporateBodiesPersonsFamilies/cmdp:CorporateBodiesPersonsFamiliesIdentityArea/cmdp:authorizedFormOfName"
                                />
                            </h1>
                        </td>
                    </tr>
                    <tr>
                        <td valign="top">
                            <h2>
                                <xsl:value-of
                                    select="//cmdp:CorporateBodiesPersonsFamilies/cmdp:CorporateBodiesPersonsFamiliesIdentityArea/cmdp:parallelFormsOfName"
                                />
                            </h2>
                            <p>
                                <b>Dates:</b>
                                <xsl:value-of
                                    select="//cmdp:CorporateBodiesPersonsFamilies/cmdp:CorporateBodiesPersonsFamiliesDescriptionArea/cmdp:datesOfExistence"
                                />
                            </p>
                            <xsl:variable name="concepts" select="//cmdp:CorporateBodiesPersonsFamilies/cmdp:CorporateBodiesPersonsFamiliesRelationshipArea/cmdp:SubjectAccess/cmdp:Relationship/cmdp:to[normalize-space()!='']"/>
                            <xsl:if test="exists($concepts)">
                                <p>
                                    
                                    <b>Related concepts:</b>
                                    <xsl:for-each select="$concepts">
                                        <xsl:choose>
                                            <xsl:when test="normalize-space(@cmd:valueConceptLink)!=''">
                                                <a href="{clariah:toURL(@cmd:valueConceptLink,'.html')}">
                                                    <xsl:value-of select="."/>
                                                </a>
                                            </xsl:when>
                                            <xsl:otherwise>
                                                <xsl:value-of select="."/>
                                            </xsl:otherwise>
                                        </xsl:choose>
                                    </xsl:for-each>
                                </p>
                            </xsl:if>
                            <xsl:variable name="locations" select="//cmdp:CorporateBodiesPersonsFamilies/cmdp:CorporateBodiesPersonsFamiliesRelationshipArea/cmdp:PlacesAccess/cmdp:Relationship/cmdp:to[normalize-space()!='']"/>
                            <xsl:if test="exists($locations)">
                                <p>
                                    
                                    <b>Related locations:</b>
                                    <xsl:for-each select="$locations">
                                        <xsl:choose>
                                            <xsl:when test="normalize-space(@cmd:valueConceptLink)!=''">
                                                <a href="{clariah:toURL(@cmd:valueConceptLink,'.html')}">
                                                    <xsl:value-of select="."/>
                                                </a>
                                            </xsl:when>
                                            <xsl:otherwise>
                                                <xsl:value-of select="."/>
                                            </xsl:otherwise>
                                        </xsl:choose>
                                    </xsl:for-each>
                                </p>
                            </xsl:if>
                            <xsl:variable name="organisations" select="//cmdp:CorporateBodiesPersonsFamilies/cmdp:CorporateBodiesPersonsFamiliesRelationshipArea/cmdp:PersonalitiesAccess/cmdp:Relationship/cmdp:to[normalize-space()!='']"/>
                            <xsl:if test="exists($organisations)">
                                <p>
                                    
                                    <b>Related organisations:</b>
                                    <xsl:for-each select="$organisations">
                                        <xsl:choose>
                                            <xsl:when test="normalize-space(@cmd:valueConceptLink)!=''">
                                                <!--<xsl:variable name="o" select="doc(clariah:toURL(@cmd:valueConceptLink,'.xml'))"/>
                                                <xsl:if test="$o//cmd:CMD//*:typeOfPersonality='Corporate Body'">-->
                                                    <a href="{clariah:toURL(@cmd:valueConceptLink,'.html')}">
                                                        <xsl:value-of select="."/>
                                                    </a>
                                                <!--</xsl:if>-->
                                            </xsl:when>
                                            <xsl:otherwise>
                                                <xsl:value-of select="."/>
                                            </xsl:otherwise>
                                        </xsl:choose>
                                    </xsl:for-each>
                                </p>
                            </xsl:if>
                            <xsl:variable name="people" select="//cmdp:CorporateBodiesPersonsFamilies/cmdp:CorporateBodiesPersonsFamiliesRelationshipArea/cmdp:PersonalitiesAccess/cmdp:Relationship/cmdp:to[normalize-space()!='']"/>
                            <xsl:if test="exists($people)">
                                <p>
                                    
                                    <b>Related people:</b>
                                    <xsl:for-each select="$people">
                                        <xsl:choose>
                                            <xsl:when test="normalize-space(@cmd:valueConceptLink)!=''">
                                                <!--<xsl:variable name="p" select="doc(clariah:toURL(@cmd:valueConceptLink,'.xml'))"/>
                                                <xsl:if test="$p//cmd:CMD//*:typeOfPersonality='Person'">-->
                                                    <a href="{clariah:toURL(@cmd:valueConceptLink,'.html')}">
                                                        <xsl:value-of select="."/>
                                                    </a>
                                                <!--</xsl:if>-->
                                            </xsl:when>
                                            <xsl:otherwise>
                                                <xsl:value-of select="."/>
                                            </xsl:otherwise>
                                        </xsl:choose>
                                    </xsl:for-each>
                                </p>
                            </xsl:if>
                        </td>
                        <td>
                            <h2>Description</h2>
                            <p>
                                <xsl:value-of select="//cmdp:CorporateBodiesPersonsFamilies/cmdp:CorporateBodiesPersonsFamiliesDescriptionArea/cmdp:history"/>
                            </p>
                            <h2>Functions and occupations</h2>
                            <p>...</p>
                            <h2>Related archival collections</h2>
                            <dl>
                                <dt>...</dt>
                                <dd>...</dd>
                            </dl>
                        </td>
                    </tr>
                </table>
                <hr style="height:12px; border-top:7px solid black; border-bottom:1px solid black;"/>
                <h1>
                    <xsl:call-template name="title"/>
                </h1>
                <dl>
                    <xsl:apply-templates select="/*:CMD/*:Components/*">
                        <xsl:with-param name="tweak" select="$tweak-doc/ComponentSpec"/>
                    </xsl:apply-templates>
                </dl>
            </body>
        </html>
    </xsl:template>

    <xsl:template match="*">
        <xsl:param name="tweak"/>
        <xsl:variable name="t" select="$tweak/*[@name = local-name(current())]"/>
        <dt class="{local-name()} level-{count(ancestor::*) - 1} {local-name($t)}">
            <xsl:choose>
                <xsl:when test="normalize-space($t/clariah:label) != ''">
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
                <xsl:otherwise>
                    <xsl:value-of select="."/>
                </xsl:otherwise>
            </xsl:choose>
        </dd>
    </xsl:template>

</xsl:stylesheet>
