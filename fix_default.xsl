<?xml version="1.0" encoding="utf-8" ?>
<xsl:stylesheet
    version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns="http://www.w3.org/1999/xhtml"
    xmlns:html="http://www.w3.org/1999/xhtml"
    exclude-result-prefixes="html">

  <xsl:output
      method="xml"
      version="1.0"
      indent="yes"
      encoding="utf-8"/>

  <xsl:param name="title" />
  <xsl:param name="compiled-xsl" />
  <xsl:param name="min-javascript" />

  <xsl:template match="*">
    <xsl:copy>
      <xsl:apply-templates select="@*" />
      <xsl:apply-templates select="*|text()" />
    </xsl:copy>
  </xsl:template>

  <xsl:template match="@*">
    <xsl:copy>
      <xsl:attribute name="{local-name()}" namespace="{namespace-uri()}">
        <xsl:value-of select="." />
      </xsl:attribute>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="html:title|html:h1">
    <xsl:element name="{local-name()}">
      <xsl:choose>
        <xsl:when test="$title">
          <xsl:value-of select="$title" />
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="." />
        </xsl:otherwise>
      </xsl:choose>
    </xsl:element>
  </xsl:template>

  <xsl:template match="xsl:import[@href='includes/sfw_debug.xsl']">
    <xsl:element name="xsl:import">
      <xsl:attribute name="href">
        <xsl:choose>
          <xsl:when test="$compiled-xsl">
            <xsl:text>includes/sfw_compiled.xsl</xsl:text>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="@href" />
          </xsl:otherwise>
        </xsl:choose>
      </xsl:attribute>
    </xsl:element>
  </xsl:template>

  <xsl:template match="xsl:with-param[@name='jscripts']">
    <xsl:element name="xsl:with-param">
      <xsl:apply-templates select="@*" />
      <xsl:choose>
        <xsl:when test="$min-javascript">min</xsl:when>
        <xsl:otherwise><xsl:value-of select="." /></xsl:otherwise>
      </xsl:choose>
    </xsl:element>
  </xsl:template>



</xsl:stylesheet>
