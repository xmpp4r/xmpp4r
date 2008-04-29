<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0"
		xmlns="http://www.w3.org/1999/xhtml"
		xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
		xmlns:j="jabber:client"
		xmlns:p="http://jabber.org/protocol/pubsub"
		xmlns:tune="http://jabber.org/protocol/tune"
		xmlns:mood="http://jabber.org/protocol/mood"
		xmlns:activity="http://jabber.org/protocol/activity"
		xmlns:chatting="http://www.xmpp.org/extensions/xep-0194.html#ns"
		xmlns:browsing="http://www.xmpp.org/extensions/xep-0195.html#ns"
		xmlns:gaming="http://www.xmpp.org/extensions/xep-0196.html#ns"
		xmlns:watching="http://www.xmpp.org/extensions/xep-0197.html#ns"
		exclude-result-prefixes="xsl j p
					 tune mood activity chatting
					 browsing gaming watching">

<xsl:output method="xml"
            version="1.0"
            encoding="utf-8"
            doctype-public="-//W3C//DTD XHTML 1.0 Strict//EN"
            doctype-system="DTD/xhtml1-strict.dtd"
            indent="yes"/>

  <xsl:template match="/items">
    <html>
      <head>
	<title>PEP aggregator</title>
	<style type="text/css">
<![CDATA[
body { font-family: sans-serif; }
h1 { text-align: center; font-weight: bold; font-family: fantasy;
font-style: italic; }
h2 { margin-top: 2em; padding: 0.5em 8em; color: black; background:
#bfbfff; }
h2 a { color: black; font-decoration: none; }
p { margin: 0.5em 4em; }
p.footnote { margin-top: 16em; font-size: 90%; }
img.avatar { max-width: 10%; clear: left; float: left; padding: 4px; }
]]>
	</style>
      </head>

      <body>
	<h1>PEP aggregator</h1>

	<xsl:apply-templates/>

	<p class="footnote">
	  This aggregator consumes events by
	  the <a href="http://www.xmpp.org/">XMPP</a>
	  extension <a href="http://www.xmpp.org/extensions/xep-0163.html">Personal
	  Eventing via Pubsub</a>.  If you want to participate you'll
	  need a PEP-enabled server
	  (<a href="http://www.ejabberd.im/">ejabberd</a>), client
	  (<a href="http://www.gajim.org/">Gajim</a>
	  or <a href="http://psi-im.org/">Psi</a>)
	  and <a href="xmpp:{@j:to}?subscribe"><xsl:value-of select="@j:to"/></a>
	  in your Jabber roster.  The source code can
	  be <a href="http://svn.gna.org/viewcvs/xmpp4r/trunk/xmpp4r/data/doc/xmpp4r/examples/advanced/pep-aggregator/">viewed
	  online</a>.
	</p>
      </body>
    </html>
  </xsl:template>

  <xsl:template match="p:item[@j:from]">
    <xsl:if test="@j:has-avatar = 'true'">
      <img class="avatar" src="/avatar/{@j:from}"/>
    </xsl:if>

    <h2>
      <a href="xmpp:{@j:from}">
	<xsl:value-of select="@j:from-name"/>
      </a>
    </h2>

    <xsl:apply-templates/>
    
  </xsl:template>

  <xsl:template match="tune:tune[count(*) = 0]">
    <p>Stopped listening</p>
  </xsl:template>

  <xsl:template match="tune:tune">
    <p>
      ♫ Listening
      <xsl:value-of select="tune:artist"/>
      —
      <xsl:value-of select="tune:source"/>
      —
      <xsl:value-of select="tune:title"/>
    </p>
  </xsl:template>

  <xsl:template match="mood:mood">
    <p>
      ☻ Feeling
      <xsl:text> </xsl:text>
      <xsl:value-of select="name(*[1])"/>
      <xsl:if test="*[1]/*[1]">
	<xsl:text> </xsl:text>
	(<xsl:value-of select="name(*[1]/*[1])"/>)
      </xsl:if>
      <xsl:if test="mood:text">
	<xsl:text> </xsl:text>
	<i><xsl:value-of select="mood:text"/></i>
      </xsl:if>
    </p>
  </xsl:template>

  <xsl:template match="activity:activity">
    <p>
      ↻ Doing
      <xsl:text> </xsl:text>
      <xsl:value-of select="name(*[1])"/>
      <xsl:if test="*[1]/*[1]">
	<xsl:text> </xsl:text>
	(<xsl:value-of select="name(*[1]/*[1])"/>)
      </xsl:if>
      <xsl:if test="activity:text">
	<xsl:text> </xsl:text>
	<i><xsl:value-of select="activity:text"/></i>
      </xsl:if>
    </p>
  </xsl:template>

  <xsl:template match="chatting:room[count(*) = 0]">
    <p>Stopped chatting</p>
  </xsl:template>

  <xsl:template match="chatting:room">
    <p>
      Chatting at
      <a href="{chatting:uri}">
	<xsl:choose>
	  <xsl:when test="chatting:name"><xsl:value-of select="chatting:name"/></xsl:when>
	  <xsl:otherwise><xsl:value-of select="chatting:uri"/></xsl:otherwise>
	</xsl:choose>
      </a>
      <xsl:if test="chatting:topic">
	<i><xsl:value-of select="chatting:topic"/></i>
      </xsl:if>
    </p>
  </xsl:template>

  <xsl:template match="browsing:page[count(*) = 0]">
    <p>Stopped browsing</p>
  </xsl:template>

  <xsl:template match="browsing:page">
    <p>
      Browsing
      <a href="{browsing:uri}">
	<xsl:choose>
	  <xsl:when test="browsing:title"><xsl:value-of select="browsing:title"/></xsl:when>
	  <xsl:otherwise><xsl:value-of select="browsing:uri"/></xsl:otherwise>
	</xsl:choose>
      </a>
      <xsl:if test="browsing:description">
	<i><xsl:value-of select="browsing:description"/></i>
      </xsl:if>
    </p>
  </xsl:template>

  <xsl:template match="gaming:game[count(*) = 0]">
    <p>Stopped gaming</p>
  </xsl:template>

  <xsl:template match="gaming:game">
    <p>

      Playing
      <xsl:choose>
	<xsl:when test="gaming:uri">
	  <a href="{gaming:uri}">
	    <xsl:value-of select="gaming:name"/>
	  </a>
	</xsl:when>
	<xsl:otherwise>
	  <xsl:value-of select="gaming:name"/>
	</xsl:otherwise>
      </xsl:choose>

      <xsl:if test="gaming:character_name">
	as
	<xsl:choose>
	  <xsl:when test="gaming:character_profile">
	    <a href="{gaming:character_profile}">
	      <xsl:value-of select="gaming:character_name"/>
	    </a>
	  </xsl:when>
	  <xsl:otherwise>
	    <xsl:value-of select="gaming:character_name"/>
	  </xsl:otherwise>
	</xsl:choose>
      </xsl:if>

      <xsl:if test="gaming:server_address">
	on
	<a href="{gaming:server_address}">
	  <xsl:choose>
	    <xsl:when test="gaming:server_name"><xsl:value-of select="gaming:server_name"/></xsl:when>
	    <xsl:otherwise><xsl:value-of select="gaming:server_name"/></xsl:otherwise>
	  </xsl:choose>
	</a>
      </xsl:if>

    </p>
  </xsl:template>

  <xsl:template match="watching:video[count(*) = 0]">
    <p>Stopped watching a video</p>
  </xsl:template>

  <xsl:template match="watching:video">
    <xsl:if test="watching:program_name">
      <p>
	✇ Watching
	<xsl:choose>
	  <xsl:when test="watching:uri">
	    <a href="{watching:uri}">
	      <xsl:value-of select="watching:program_name"/>
	    </a>
	  </xsl:when>
	  <xsl:otherwise>
	    <xsl:value-of select="watching:program_name"/>
	  </xsl:otherwise>
	</xsl:choose>
      </p>
    </xsl:if>
  </xsl:template>

</xsl:stylesheet>
