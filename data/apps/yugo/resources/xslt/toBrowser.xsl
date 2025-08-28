<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:err="http://www.w3.org/2005/xqt-errors" xmlns:clariah="http://www.clariah.eu/"
    xmlns:yugo="http://yugo.niod.nl/" xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:functx="http://www.functx.com" exclude-result-prefixes="clariah err yugo xs functx"
    version="3.0">

    <xsl:output method="xml" omit-xml-declaration="yes"/>

    <xsl:param name="cwd" select="'file:/Users/menzowi/Documents/Projects/huc-cmdi-editor/service/'"/>
    <xsl:param name="base" select="'http://host.docker.internal:1211'"/>
    <xsl:param name="app" select="'adoptie'"/>
    <xsl:param name="nr" select="'1'"/>
    <xsl:param name="config" select="doc(concat($cwd, '/data/apps/', $app, '/config.xml'))"/>
    <xsl:param name="prof" select="$config/config/app/def_prof"/>
    <xsl:param name="graph"/>

    <xsl:param name="style" select="'style.css'"/>
    <xsl:param name="tweak-uri" select="''"/>
    <xsl:param name="tweak-doc" select="document($tweak-uri)"/>

    <xsl:variable name="rec" select="/"/>

    <xsl:function name="functx:capitalize-first" as="xs:string?">
        <xsl:param name="arg" as="xs:string?"/>

        <xsl:sequence select="
                concat(upper-case(substring($arg, 1, 1)),
                substring($arg, 2))
                "/>

    </xsl:function>
    
    <xsl:function name="functx:camel-case-to-words" as="xs:string">
        <xsl:param name="arg" as="xs:string?"/>
        <xsl:param name="delim" as="xs:string"/>

        <xsl:sequence select="
                concat(substring($arg, 1, 1),
                replace(substring($arg, 2), '(\p{Lu})',
                concat($delim, '$1')))
                "/>

    </xsl:function>

    <xsl:function name="yugo:toLang">
        <xsl:param name="lang"/>
        <xsl:choose>
            <xsl:when test="$lang = 'en'">
                <xsl:value-of select="'English'"/>
            </xsl:when>
            <xsl:when test="$lang = 'fr'">
                <xsl:value-of select="'French'"/>
            </xsl:when>
            <xsl:when test="$lang = 'bos'">
                <xsl:value-of select="'Bosnian'"/>
            </xsl:when>
            <xsl:when test="$lang = 'hrv'">
                <xsl:value-of select="'Croatian'"/>
            </xsl:when>
            <xsl:when test="$lang = 'srp'">
                <xsl:value-of select="'Serbian'"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="'other'"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <xsl:function name="yugo:toEnt">
        <xsl:param name="ent"/>
        <xsl:choose>
            <xsl:when test="$ent = 'group'">
                <xsl:value-of select="'organisation'"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$ent"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

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

    <xsl:template match="text()"/>

    <xsl:template name="title">
        <!--<xsl:comment expand-text="yes">
             prof[{$prof}]
             xpath[{$config/config/app/prof/*[prof=$prof]/title}]
             </xsl:comment>-->
        <xsl:variable name="xpath" select="$config/config/app/prof/*[prof = $prof]/title"/>
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
            <xsl:variable name="type"
                select="(/*:CMD/*:Components/*:Collection/*:Identification/*:type, /*:CMD/*:Components/*:Group/*:Identification/*:type), /*:CMD/*:Components/*:Event/*:Identification/*:type[1]"/>
            <xsl:if test="normalize-space($type) != ''">
                <p class="type">
                    <xsl:value-of select="$type"/>
                </p>
            </xsl:if>
            <xsl:for-each select="//*:Names/*:parallelForms">
                <div class="parallelForms">
                    <xsl:value-of select="."/>
                    <span class="lang">
                        <xsl:value-of select="yugo:toLang(@xml:lang)"/>
                    </span>
                </div>
            </xsl:for-each>
            <xsl:for-each select="//*:Names/*:otherForms">
                <div class="parallelForms">
                    <xsl:value-of select="."/>
                    <span class="lang">
                        <xsl:value-of select="yugo:toLang(@xml:lang)"/>
                    </span>
                </div>
            </xsl:for-each>
            <xsl:variable name="id" select="replace($rec//*:MdSelfLink, 'unl://', '')"/>
            <xsl:variable name="ent" select="local-name($rec//*:Components/*)"/>
            <xsl:choose>
                <xsl:when test="$ent = 'CollectionHoldingInstitution'">
                    <xsl:apply-templates select="$graph//collectionHierarchy/institution[@id = $id]"
                        mode="yourehere">
                        <xsl:with-param name="here" select="$id" tunnel="yes"/>
                        <xsl:with-param name="ent" select="'institution'" tunnel="yes"/>
                    </xsl:apply-templates>
                </xsl:when>
                <xsl:when test="$ent = 'Collection'">
                    <xsl:apply-templates
                        select="$graph//collectionHierarchy/institution[.//collection[@id = $id]]"
                        mode="yourehere">
                        <xsl:with-param name="here" select="$id" tunnel="yes"/>
                        <xsl:with-param name="ent" select="'collection'" tunnel="yes"/>
                    </xsl:apply-templates>
                </xsl:when>
            </xsl:choose>
            <xsl:apply-templates select="/*:CMD/*:Components/*">
                <xsl:with-param name="tweak" select="$tweak-doc/ComponentSpec"/>
            </xsl:apply-templates>
            <hr/>
            <h2 class="RelationShipArea component">Relationships</h2>
            <xsl:if test="exists($graph//edge[to/@id = $id][to/@prof = $prof])">
                <xsl:variable name="rels" select="$graph//edge[*[@id = $id and @prof = $prof]]/*[not(@id = $id and @prof = $prof)]"/>
                <xsl:for-each-group select="$rels" group-by="@ent">
                    <xsl:sort select="current-grouping-key()"/>
                    <h3 class="from level-1 element">
                        <xsl:value-of select="concat(functx:capitalize-first(yugo:toEnt(current-grouping-key())),'s')"/>
                    </h3>
                    <ul>
                        <xsl:for-each-group select="current-group()" group-by="concat(@id,'@',@ent)">
                            <xsl:variable name="e" select="."/>
                            <li>
                                <a href="/{$e/@ent}_detail/{$e/@id}" class="rel">
                                    <xsl:value-of select="$e/@title"/>
                                </a>
                                <!--<span class="ent">
                                    <xsl:value-of select="yugo:toEnt($e/@ent)"/>
                                </span>-->
                            </li>
                        </xsl:for-each-group>
                    </ul>
                </xsl:for-each-group>
            </xsl:if>
        </div>
        <!--</body>
        </html>-->
    </xsl:template>

    <xsl:template match="*" mode="yourehere">
        <xsl:param name="here" tunnel="yes"/>
        <xsl:param name="ent" tunnel="yes"/>
        <dl>
            <dt>
                <xsl:choose>
                    <xsl:when test="@id = $here and $ent = local-name()">
                        <span class="here">&#160;</span>
                        <xsl:value-of select="@title"/>
                        <span class="ent">
                            <xsl:value-of select="yugo:toEnt(local-name())"/>
                        </span>
                    </xsl:when>
                    <xsl:otherwise>
                        <a href="/{local-name()}_detail/{@id}">
                            <xsl:value-of select="@title"/>
                        </a>
                        <span class="ent">
                            <xsl:value-of select="yugo:toEnt(local-name())"/>
                        </span>
                    </xsl:otherwise>
                </xsl:choose>
            </dt>
            <dd>
                <dl>
                    <xsl:apply-templates mode="#current"/>
                </dl>
            </dd>
        </dl>
    </xsl:template>

    <xsl:template name="continue">
        <xsl:param name="tweak"/>
        <xsl:variable name="t" select="$tweak/*[@name = local-name(current())]"/>
        <xsl:apply-templates>
            <xsl:with-param name="tweak" select="$t"/>
        </xsl:apply-templates>
    </xsl:template>
    
    <xsl:template name="section-title">
        <xsl:param name="tweak"/>
        <xsl:variable name="t" select="$tweak/*[@name = local-name(current())]"/>
        <hr/>
        <h2 class="{local-name()} level-{count(ancestor::*) - 1} {local-name($t)}">
            <xsl:choose>
                <xsl:when test="normalize-space($t/clariah:label) != ''">
                    <xsl:value-of select="normalize-space($t/clariah:label)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of
                        select="functx:capitalize-first(functx:camel-case-to-words(string(local-name()), ' '))"
                    />
                </xsl:otherwise>
            </xsl:choose>
        </h2>
    </xsl:template>

    <xsl:template name="section">
        <xsl:param name="tweak"/>
        <xsl:call-template name="section-title">
            <xsl:with-param name="tweak" select="$tweak"/>
        </xsl:call-template>
        <xsl:call-template name="continue">
            <xsl:with-param name="tweak" select="$tweak"/>
        </xsl:call-template>
    </xsl:template>

    <xsl:template name="field">
        <xsl:param name="tweak"/>
        <xsl:variable name="t" select="$tweak/*[@name = local-name(current())]"/>
        <h3 class="{local-name()} level-{count(ancestor::*) - 1} {local-name($t)}">
            <xsl:choose>
                <xsl:when test="normalize-space($t/clariah:label) != ''">
                    <xsl:value-of select="normalize-space($t/clariah:label)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of
                        select="functx:capitalize-first(functx:camel-case-to-words(string(local-name()), ' '))"
                    />
                </xsl:otherwise>
            </xsl:choose>
        </h3>
    </xsl:template>

    <xsl:template name="value">
        <xsl:param name="tweak"/>
        <xsl:variable name="t" select="$tweak/*[@name = local-name(current())]"/>
        <xsl:choose>
            <xsl:when test="*">
                <xsl:apply-templates>
                    <xsl:with-param name="tweak" select="$t"/>
                </xsl:apply-templates>
            </xsl:when>
            <xsl:when test="normalize-space(@*:valueConceptLink) != ''">
                <xsl:choose>
                    <xsl:when test="matches(@*:valueConceptLink, '/entity/([^/]+)/([0-9]+)$')">
                        <xsl:variable name="rec"
                            select="replace(@*:valueConceptLink, '.*/entity/[^/]+/([0-9]+)$', '$1')"/>
                        <xsl:variable name="ent"
                            select="replace(@*:valueConceptLink, '.*/entity/([^/]+)/[0-9]+$', '$1')"/>
                        <a href="/{$ent}_detail/{$rec}">
                            <xsl:value-of select="."/>
                        </a>
                    </xsl:when>
                    <xsl:when test="matches(@*:valueConceptLink, '^ref:/')">
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
            <xsl:when test="starts-with(normalize-space(.),'http://') or starts-with(normalize-space(.),'https://')">
                <a href="{normalize-space(.)}" target="{local-name()}">
                    <xsl:value-of select="."/>
                </a>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="."/>
            </xsl:otherwise>
        </xsl:choose>

    </xsl:template>

    <xsl:template match="*:Components/*" priority="100">
        <xsl:param name="tweak"/>
        <xsl:call-template name="continue">
            <xsl:with-param name="tweak" select="$tweak"/>
        </xsl:call-template>
    </xsl:template>

    <xsl:template match="*:status" priority="100"/>
    <xsl:template match="*:type" priority="100"/>
    <xsl:template match="*:Names" priority="100"/>
    <xsl:template match="*:ControlArea" priority="100"/>
    <xsl:template match="*:RelationshipArea" priority="100"/>
    
    <xsl:template match="*:Identification" priority="100">
        <xsl:param name="tweak"/>
        <xsl:call-template name="continue">
            <xsl:with-param name="tweak" select="$tweak"/>
        </xsl:call-template>
    </xsl:template>

    <xsl:template match="*:CollectionHoldingInstitutionContactArea" priority="100">
        <xsl:param name="tweak"/>
        <xsl:call-template name="section-title">
            <xsl:with-param name="tweak" select="$tweak"/>
        </xsl:call-template>
        <!--<cmdp:CollectionHoldingInstitutionContactArea>
            <cmdp:address>Churchillplein 1 2517 JW</cmdp:address>
            <cmdp:city xml:lang="en">The Hague</cmdp:city>
            <cmdp:regionProvince xml:lang="en">Zuid Holland</cmdp:regionProvince>
            <cmdp:country xml:lang="en">The Netherlands</cmdp:country>
            <cmdp:telephoneNumber>0031 (0)70 512 5037</cmdp:telephoneNumber>
            <cmdp:email>marshague@un.org</cmdp:email>
            <cmdp:website>https://www.irmct.org/en</cmdp:website>
        </cmdp:CollectionHoldingInstitutionContactArea>-->
        <xsl:value-of select="normalize-space(*:address)"/>
        <br/>
        <xsl:value-of select="normalize-space((*:city[@xml:lang='en'],*:city)[1])"/>
        <xsl:if test="normalize-space((*:regionProvince[@xml:lang='en'],*:regionProvince)[1])!=''">
            <xsl:text>, </xsl:text>
            <xsl:value-of select="normalize-space((*:regionProvince[@xml:lang='en'],*:regionProvince)[1])"/>
        </xsl:if>
        <xsl:if test="normalize-space((*:country[@xml:lang='en'],*:country)[1])!=''">
            <xsl:text>, </xsl:text>
            <xsl:value-of select="normalize-space((*:country[@xml:lang='en'],*:country)[1])"/>
        </xsl:if>
        <br/>
        <xsl:for-each select="*:telephoneNumber[normalize-space(.)!='']">
            <xsl:text>&#9743; </xsl:text>
            <xsl:value-of select="normalize-space(.)"/>
            <br/>
        </xsl:for-each>
        <xsl:for-each select="*:email[normalize-space(.)!='']">
            <xsl:text>&#9993; </xsl:text>
            <a href="mailto:{normalize-space(.)}">
                <xsl:value-of select="normalize-space(.)"/>
            </a>
            <br/>
        </xsl:for-each>
        <xsl:for-each select="*:website[normalize-space(.)!='']">
            <xsl:text>&#127760; </xsl:text>
            <a href="{normalize-space(.)}" target="contact">
                <xsl:value-of select="normalize-space(.)"/>
            </a>
            <br/>
        </xsl:for-each>
    </xsl:template>

    <xsl:template match="*[exists(*)]" priority="10">
        <xsl:param name="tweak"/>
        <xsl:call-template name="section">
            <xsl:with-param name="tweak" select="$tweak"/>
        </xsl:call-template>
    </xsl:template>

    <xsl:template match="*[empty(*)]" priority="10">
        <xsl:param name="tweak"/>
        <xsl:call-template name="field">
            <xsl:with-param name="tweak" select="$tweak"/>
        </xsl:call-template>
        <xsl:call-template name="value">
            <xsl:with-param name="tweak" select="$tweak"/>
        </xsl:call-template>
    </xsl:template>


    <xsl:template match="*:IdentifierExternal/*:uri">
        <xsl:param name="tweak"/>
        <xsl:variable name="t" select="$tweak/*[@name = local-name(current())]"/>
        <!-- <dt class="{local-name()} level-{count(ancestor::*) - 1} {local-name($t)}">-->
        <xsl:choose>
            <xsl:when test="normalize-space($t/clariah:label) != ''">
                <xsl:value-of select="normalize-space($t/clariah:label)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="local-name()"/>
            </xsl:otherwise>
        </xsl:choose>
        <!--</dt>-->
        <!--<dd class="{local-name()} level-{count(ancestor::*) - 1} {local-name($t)}">-->
        <xsl:choose>
            <xsl:when test="matches(., 'http(s)?://')">
                <a href="{.}" target="external">
                    <xsl:value-of select="."/>
                </a>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="."/>
            </xsl:otherwise>
        </xsl:choose>
        <!--</dd>-->
    </xsl:template>

    <!--   <xsl:template match="*">
        <xsl:param name="tweak"/>
        <xsl:variable name="t" select="$tweak/*[@name=local-name(current())]"/>
        <h2 class="{local-name()} level-{count(ancestor::*) - 1} {local-name($t)}">
            <xsl:choose>
                <xsl:when test="normalize-space($t/clariah:label)!=''">
                    <xsl:value-of select="normalize-space($t/clariah:label)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="functx:capitalize-first(functx:camel-case-to-words(string(local-name()), ' '))"/>
                </xsl:otherwise>
            </xsl:choose>
        </h2>
        <!-\-<dd class="{local-name()} level-{count(ancestor::*) - 1} {local-name($t)}">-\->
            <xsl:choose>
                <xsl:when test="*">
                    <!-\-<dl>-\->
                        <xsl:apply-templates>
                            <xsl:with-param name="tweak" select="$t"/>
                        </xsl:apply-templates>
                    <!-\-</dl>-\->
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
        <!-\-</dd>-\->
    </xsl:template>        
-->
</xsl:stylesheet>
