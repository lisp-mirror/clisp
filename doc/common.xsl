<?xml version="1.0"?>
<!DOCTYPE xsl:stylesheet [
          <!ENTITY lowercase "'abcdefghijklmnopqrstuvwxyz'">
          <!ENTITY uppercase "'ABCDEFGHIJKLMNOPQRSTUVWXYZ'">
]>

<!-- common settings for CLISP Implementation Notes formatting -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns="http://www.w3.org/1999/xhtml"
                xmlns:date="http://exslt.org/dates-and-times"
                exclude-result-prefixes="date"
                version="1.0">

<!-- https://lists.oasis-open.org/archives/docbook-apps/200903/msg00123.html -->
<!-- side effect of this empty param is to output a message -->
<xsl:param name="__output.version__"><xsl:message>
 <xsl:text>DocBook XSL stylesheet VERSION is: </xsl:text>
 <xsl:value-of select="$VERSION"/>
</xsl:message></xsl:param>

<!-- http://www.sagehill.net/docbookxsl/HtmlHead.html -->
<xsl:param name="html.stylesheet" select="'impnotes.css'"/>
<xsl:param name="link.mailto.url"
           select="'mailto:clisp-list@lists.sourceforge.net'"/>
<!-- xsl:param name="suppress.navigation" select="0"/-->
<xsl:param name="inherit.keywords" select="0"/>
<xsl:param name="variablelist.term.break.after" select="1"/>
<xsl:param name="variablelist.term.separator" select="''"/>
<xsl:param name="generate.meta.abstract" select="1"/>

<!-- https://sourceforge.net/p/docbook/bugs/990/ -->
<xsl:param name="index.links.to.section" select="0"/>

<!-- http://www.sagehill.net/docbookxsl/HtmlHead.html -->
<xsl:variable name="processing.time">
 <xsl:call-template name="datetime.format">
  <xsl:with-param name="date" select="date:date-time()"/>
  <xsl:with-param name="format" select="'Y-m-d X'"/>
</xsl:call-template></xsl:variable>

<xsl:variable name="faq.help.target" select="key('id','faq-help')"/>
<xsl:variable name="help.href">
 <xsl:call-template name="href.target">
  <xsl:with-param name="object" select="$faq.help.target"/>
</xsl:call-template></xsl:variable>
<xsl:variable name="help.title">
 <xsl:variable name="question.content">
  <xsl:apply-templates select="$faq.help.target/question/node()"/>
 </xsl:variable>
 <xsl:value-of select="normalize-space($question.content)"/></xsl:variable>

<xsl:variable name="glossary.target" select="key('id','glossary')"/>
<xsl:variable name="glossary.href">
 <xsl:call-template name="href.target">
  <xsl:with-param name="object" select="$glossary.target"/>
</xsl:call-template></xsl:variable>

<xsl:variable name="authors.target" select="key('id','authors')"/>
<xsl:variable name="authors.href">
 <xsl:call-template name="href.target">
  <xsl:with-param name="object" select="$authors.target"/>
</xsl:call-template></xsl:variable>

<xsl:template name="user.head.content">
 <meta name="date" content="'generated: {$processing.time}'"/>
 <link rel="author" title="Authors" href="{$authors.href}"/>
 <link rel="contents" title="Table of Contents" href="index.html"/>
 <link rel="glossary" href="{$glossary.href}"/>
 <link rel="help" href="{$help.href}" title="{$help.title}"/>
 <link rel="home" title="Home" href="http://clisp.org"/>
 <link rel="index" href="idx.html"/>
</xsl:template>

<xsl:preserve-space elements="entry"/>

<!-- apply-templates is mapc on children
     apply-imports is call-next-method -->

<xsl:template match="ulink[@url='google']">
 <a class="{@role}" href="http://www.google.com/search?q={.}"
    ><xsl:apply-templates/></a></xsl:template>

<xsl:template match="ulink[@url='usenet']">
  <xsl:text>the USENET newsgroup </xsl:text>
  <a class="{@role}" href="https://groups.google.com/group/{.}"
     ><xsl:apply-templates/></a></xsl:template>

<xsl:template match="ulink[@url='ml']">
  <a class="{@role}" href="https://sourceforge.net/p/clisp/mailman/{.}/"
     ><xsl:apply-templates/></a></xsl:template>

<!-- =============================== RFC =============================== -->
<xsl:param name="rfc.top" select="'http://www.ietf.org/rfc/rfc'"/>
<xsl:template match="ulink[@role='rfc']">
 <a class="{@role}" href="{$rfc.top}{@url}.txt"><code>
   <xsl:choose><xsl:when test=".=''"><xsl:text>RFC</xsl:text>
     <xsl:value-of select="@url"/></xsl:when>
    <xsl:otherwise><xsl:apply-templates/></xsl:otherwise></xsl:choose>
 </code></a>
</xsl:template>
<!-- ============================== / RFC ============================== -->

<!-- ============================ CLISP CVS ============================ -->
<xsl:param name="clisp.cvs.file" select="'https://gitlab.com/gnu-clisp/clisp/blob/master/'"/>
<xsl:param name="clisp.cvs.dir" select="'https://gitlab.com/gnu-clisp/clisp/tree/master/'"/>
<xsl:template name="clisp.cvs"> <!-- prepend the correct clisp git url -->
 <xsl:param name="path"/>
 <!-- xsltproc does not support ends-with - see http://www.w3.org/TR/xpath -->
 <xsl:choose><xsl:when test="substring($path,string-length($path)) = '/'">
   <xsl:value-of select="$clisp.cvs.dir"/></xsl:when>
  <xsl:otherwise><xsl:value-of select="$clisp.cvs.file"/>
 </xsl:otherwise></xsl:choose><xsl:value-of select="$path"/>
</xsl:template>
<xsl:template match="ulink[@role='clisp-cvs']">
 <a class="{@role}">
  <xsl:attribute name="href"><xsl:call-template name="clisp.cvs">
    <xsl:with-param name="path" select="@url"/>
  </xsl:call-template></xsl:attribute>
  <xsl:apply-templates/></a>
</xsl:template>
<xsl:template match="filename[@role='clisp-cvs']">
 <a class="{@role}">
  <xsl:attribute name="href"><xsl:call-template name="clisp.cvs">
    <xsl:with-param name="path" select="."/>
  </xsl:call-template></xsl:attribute>
  <xsl:apply-imports/></a>
</xsl:template>
<xsl:template match="filename[@role='module']">
 <span class="{@role}">
  <xsl:choose><xsl:when test="@path"><xsl:call-template name="simple.xlink">
     <xsl:with-param name="linkend" select="@path"/>
     <xsl:with-param name="node" select="."/>
     <xsl:with-param name="content"><xsl:apply-imports/></xsl:with-param>
   </xsl:call-template></xsl:when>
   <xsl:otherwise><a href="{$clisp.cvs.dir}modules/{.}/">
     <xsl:apply-imports/></a></xsl:otherwise>
 </xsl:choose></span>
</xsl:template>
<!-- =========================== / CLISP CVS =========================== -->

<!-- ======= The Open Group Base Specifications Issue 6 (SUS v3) ======= -->
<xsl:param name="unix.top" select="'http://pubs.opengroup.org/onlinepubs/9699919799/'"/>
<xsl:template match="function[@role='unix'] | varname[@role='unix']">
 <a class="{@role}" href="{$unix.top}functions/{.}.html"
    ><xsl:apply-imports/></a>
</xsl:template>

<xsl:template match="command[@role='unix']">
 <a class="{@role}" href="{$unix.top}utilities/{substring-before(concat(normalize-space(.),' '),' ')}.html"><xsl:apply-imports/></a>
</xsl:template>

<xsl:template match="ulink[@role='unix']">
 <a class="{@role}" href="{$unix.top}{@url}"><xsl:apply-templates/></a>
</xsl:template>

<xsl:template match="filename[@role='unix']">
 <a class="{@role}" href="{$unix.top}basedefs/{translate(.,'/','_')}.html"
    >&lt;<xsl:apply-imports/>&gt;</a> <!-- formatting for &lt;/&gt;? -->
 <!-- xsl:call-template name="filename">&lt;<xsl:value-of select="."/>&gt;</xsl:call-template -->
</xsl:template>
<!-- ====== / The Open Group Base Specifications Issue 6 (SUS v3) ====== -->

<!-- =========== BSD functions ============ -->
<xsl:template match="function[@role='bsd'] | varname[@role='bsd']">
 <a class="{@role}" href="http://www.freebsd.org/cgi/man.cgi?query={.}"
    ><xsl:apply-imports/></a>
</xsl:template>
<!-- =========== / BSD functions ============ -->

<!-- =========== GNU functions ============ -->
<xsl:template match="function[@role='gnu'] | varname[@role='gnu']">
 <a class="{@role}" href="http://www.kernel.org/doc/man-pages/online/pages/man3/{.}.3.html"><xsl:apply-imports/></a>
</xsl:template>
<!-- =========== / GNU functions ============ -->

<!-- =========== PostGreSQL functions ============ -->
<xsl:template match="function[@role='pq'] | varname[@role='pq']">
 <a class="{@role}" href="http://www.postgresql.org/search/?q={.}">
  <xsl:apply-imports/></a>
</xsl:template>
<!-- =========== / PostGreSQL functions ============ -->

<!-- =========== Win32 functions ============ -->
<xsl:template match="function[@role='win32'] | varname[@role='win32']">
 <a class="{@role}" href="https://social.msdn.microsoft.com/search/en-US/windows?query={.}"><xsl:apply-imports/></a>
</xsl:template>
<!-- =========== / Win32 functions ============ -->

<!-- =========================== Berkeley DB =========================== -->
<!-- xsl:param name="bdb.top" select="'http://www.sleepycat.com/docs/'"/ -->
<xsl:param name="bdb.api" select="'http://docs.oracle.com/cd/E17076_02/html/api_reference/C/'"/>
<xsl:param name="bdb.doc" select="'http://download.oracle.com/otndocs/products/berkeleydb/html/'"/>

<xsl:template match="ulink[@role='bdb']">
 <a class="{@role}" href="{$bdb.doc}{@url}"><xsl:apply-templates/></a>
</xsl:template>

<xsl:template match="function[@role='bdb']">
 <a class="{@role}"><xsl:attribute name="href">
   <xsl:value-of select="$bdb.api"/>
   <xsl:choose>
    <xsl:when test=".='db_create'"><xsl:text>db_class</xsl:text></xsl:when>
    <xsl:when test=".='db_env_create'"><xsl:text>env_class</xsl:text></xsl:when>
    <xsl:when test=".='db_sequence_create'">
     <xsl:text>seq_class</xsl:text></xsl:when>
    <xsl:when test=".='db_strerror'">
     <xsl:text>env_strerror</xsl:text></xsl:when>
    <xsl:when test=".='db_version'"><xsl:text>env_version</xsl:text></xsl:when>
    <xsl:when test=".='log_compare'"><xsl:text>log_compare</xsl:text></xsl:when>
    <xsl:when test="starts-with(.,'DB_LOGC-')">
     <xsl:text>logc</xsl:text></xsl:when>
    <xsl:when test="starts-with(.,'DB_TXN-')">
     <xsl:text>txn</xsl:text></xsl:when>
    <xsl:when test="starts-with(.,'DB_ENV-')">
     <xsl:text>env</xsl:text></xsl:when>
    <xsl:when test="starts-with(.,'DB_SEQUENCE-')">
     <xsl:text>seq</xsl:text></xsl:when>
    <xsl:when test="starts-with(.,'DB_MPOOLFILE-')">
     <xsl:text>memp</xsl:text></xsl:when>
    <xsl:when test="starts-with(.,'DBCursor-')">
     <xsl:text>dbc</xsl:text></xsl:when>
    <xsl:when test="starts-with(.,'DB-')">
     <xsl:text>db</xsl:text></xsl:when>
    <xsl:otherwise><xsl:message>unknown function/db element <xsl:value-of select="."/></xsl:message></xsl:otherwise>
   </xsl:choose>
   <xsl:value-of select="substring-after(.,'>')"/>
   <xsl:text>.html</xsl:text>
  </xsl:attribute>
  <xsl:apply-imports/>
</a></xsl:template>
<!-- ========================== / Berkeley DB ========================== -->

<!-- ========================== Matlab C API ========================== -->
<xsl:param name="matlab.top" select="'https://www.mathworks.com/help/matlab/apiref/'"/>
<xsl:template match="function[@role='matlab'] | varname[@role='matlab']">
 <a class="{@role}" href="{$matlab.top}{translate(.,&uppercase;,&lowercase;)}.html"><xsl:apply-imports/></a>
</xsl:template>
<xsl:template match="ulink[@role='matlab']">
 <a class="{@role}" href="{$matlab.top}{@url}"><xsl:apply-templates/></a>
</xsl:template>
<!-- ========================= / Matlab C API ========================= -->

<!-- ========================== Netica C API ========================== -->
<xsl:param name="netica.top"
           select="'http://norsys.com/onLineAPIManual/functions/'"/>
<xsl:template match="function[@role='netica'] | varname[@role='netica']">
 <a class="{@role}" href="{$netica.top}{.}.html"><xsl:apply-imports/></a>
</xsl:template>
<!-- ========================= / Netica C API ========================= -->

<!-- ========================== dictionary ========================== -->
<xsl:param name="dict.top" select="'http://foldoc.org/'"/>
<xsl:template match="*[@role='dict']">
 <a class="{@role}" href="{$dict.top}{.}"><xsl:apply-imports/></a>
</xsl:template>
<!-- ========================= / dictionary ========================= -->

<xsl:template match="literal[@role = 'type'
      or @role = 'method' or @role = 'data' or @role = 'byte']">
 <span class="{@role}"><xsl:apply-imports/></span>
</xsl:template>

<!-- ========================== CLHS ========================== -->
<xsl:param name="clhs.top" select="'http://www.ai.mit.edu/projects/iiip/doc/CommonLISP/HyperSpec/'"/>
<xsl:param name="clhs.body" select="concat($clhs.top, 'Body/')"/>
<xsl:template match="ulink[@role='clhs']">
 <xsl:choose><xsl:when test=".=''">
   <a class="{@role}" href="{$clhs.body}{@url}.html"><xsl:text>[</xsl:text>
    <xsl:value-of select="@url"/>
    <xsl:text>]</xsl:text></a></xsl:when>
  <xsl:otherwise>
   <a class="{@role}" href="{$clhs.body}{@url}.html"><xsl:apply-templates/></a>
</xsl:otherwise></xsl:choose></xsl:template>

<xsl:template match="ulink[@url='clhs/glo']">
 <a class="{@role}" href="{$clhs.body}glo_{substring(.,1,1)}.html#{translate(normalize-space(.),' ','_')}">
  <xsl:apply-templates/></a></xsl:template>

<xsl:template match="literal[@role = '#lt']">
 <span class="data">
  <!-- assume that literal == inline.monoseq -->
  <xsl:call-template name="inline.monoseq">
   <xsl:with-param name="content">
    <a href="{$clhs.body}sec_2-4-8-20.html"><xsl:text>#&lt;</xsl:text></a>
    <xsl:apply-templates/>
    <xsl:text>&gt;</xsl:text>
   </xsl:with-param>
  </xsl:call-template>
 </span>
</xsl:template>
<!-- ========================== /CLHS ========================== -->

<!-- https://lists.oasis-open.org/archives/docbook-apps/200906/msg00074.html
     avoid line breaks in lineannotation from xref titles -->
<xsl:template match="title/text()" mode="no.anchor.mode">
 <xsl:value-of select="translate(., '&#10;', '&#32;')"/>
</xsl:template>

<xsl:template match="revision/revnumber" mode="titlepage.mode">
 <span class="revnumber"><xsl:apply-imports/></span>
</xsl:template>

<xsl:template match="revision/date" mode="titlepage.mode">
 <span class="revdate"><xsl:apply-imports/></span>
</xsl:template>

<xsl:param name="local.l10n.xml" select="document('')"/>
<l:i18n xmlns:l="http://docbook.sourceforge.net/xmlns/l10n/1.0">
 <l:l10n language="en">
  <l:gentext key="RevHistory" text="CLISP Release History"/>
  <l:gentext key="Revision" text="Release"/>
 </l:l10n>
</l:i18n>

<xsl:template match="emphasis[@role = 'plat-dep']">
 <span class="{@role}">
  <xsl:text>Platform Dependent: </xsl:text>
  <xsl:apply-imports/>
 </span>
</xsl:template>

<xsl:template match="isbn" mode="bibliography.mode">
 <xsl:text>ISBN&#160;</xsl:text>
 <xsl:apply-templates mode="bibliography.mode"/>
 <xsl:value-of select="$biblioentry.item.separator"/>
</xsl:template>

<xsl:template match="quote[@role = 'package']">
 <strong class="{@role}"><xsl:apply-imports/></strong>
</xsl:template>

<xsl:template match="quote[@role = 'format']">
 <span class="{@role}"><xsl:apply-imports/></span>
</xsl:template>

<xsl:template match="firstterm">
 <strong class="first"><xsl:apply-imports/></strong>
</xsl:template>

<xsl:template match="programlisting/computeroutput">
 <xsl:text>&#8658;&#160;</xsl:text> <!-- &rArr; + &nbsp; -->
 <xsl:apply-imports/>
</xsl:template>

<xsl:template match="programlisting[@language = 'lisp']/lineannotation">
 <strong>&#9;;&#160;</strong> <!-- TAB + ; + &nbsp; -->
 <xsl:apply-imports/>
</xsl:template>

<xsl:template match="screen/userinput">
 <big ><xsl:apply-imports/></big></xsl:template>
<xsl:template match="screen/prompt">
 <strong><xsl:apply-imports/></strong></xsl:template>

<!-- https://lists.oasis-open.org/archives/docbook-apps/200806/msg00000.html
     https://lists.oasis-open.org/archives/docbook-apps/200806/msg00016.html
     list examples in the section toc -->
<xsl:param name="generate.toc">
appendix  toc,title
article/appendix  nop
article   toc,title
book      toc,title,figure,table,example,equation
chapter   toc,title
part      toc,title
preface   toc,title
qandadiv  toc
qandaset  toc
reference toc,title
sect1     toc
sect2     toc
sect3     toc
sect4     toc
sect5     toc
section   toc,example
set       toc,title
</xsl:param>

<xsl:template name="section.toc">
 <xsl:param name="toc-context" select="."/>
 <xsl:param name="toc.title.p" select="true()"/>

 <xsl:call-template name="make.lots">
  <xsl:with-param name="toc.params" select="'toc,title,example'"/>
  <xsl:with-param name="toc">
   <xsl:call-template name="make.toc">
    <xsl:with-param name="toc-context" select="$toc-context"/>
    <xsl:with-param name="toc.title.p" select="$toc.title.p"/>
    <xsl:with-param name="toc.params" select="'toc,title,example'"/>
    <xsl:with-param name="nodes"
		    select="section|sect1|sect2|sect3|sect4|sect5|refentry
			    |bridgehead[$bridgehead.in.toc != 0]"/>
   </xsl:call-template>
  </xsl:with-param>
 </xsl:call-template>
</xsl:template>

<xsl:param name="generate.section.toc.level" select="10"/>
<xsl:param name="toc.section.depth" select="10"/>
<xsl:param name="toc.max.depth" select="3"/>
<xsl:param name="generate.index" select="1"/>
<xsl:param name="refentry.generate.title" select="1"/>
<xsl:param name="use.id.as.filename" select="1"/>
<xsl:param name="section.autolabel" select="1"/>
<xsl:param name="section.label.includes.component.label" select="1"/>

<xsl:param name="google.ads" select="0"/>
<xsl:template name="user.footer.content">
 <xsl:if test="/refentry/refentryinfo"><div class="refentryinfo">
   <hr /><table width="100%" summary="man page meta info">
    <th><td align="left">
      <xsl:apply-templates select="/refentry/refentryinfo/title/node()"/>
     </td><td align="center">
      <xsl:apply-templates select="/refentry/refentryinfo/subtitle/node()"/>
     </td><td align="right">
      <xsl:apply-templates select="/refentry/refentryinfo/date/node()"/>
 </td></th></table></div></xsl:if>
 <xsl:if test="/book/bookinfo"><div class="bookinfo">
   <hr /><table width="100%" summary="impnotes meta info">
    <th><td align="left">
      <xsl:apply-templates select="/book/bookinfo/subtitle/node()"/>
     </td><td align="right">
      <xsl:apply-templates select="/book/bookinfo/date/node()"/>
 </td></th></table></div></xsl:if>
 <div class="custom-footer"><hr /><table width="100%">
   <tr><td align="left"><a href="http://clisp.org">
      <img src="clisp.png" width="48" height="48" alt="[CLISP home]"/></a></td>
   </tr></table></div><hr />
 <!-- https://sourceforge.net/p/alexandria/support-requests/122850/ -->
 <form method="get" action="http://www.google.com/custom" target="_top">
  <table width="100%" border="0"><tr>
    <td nowrap="nowrap" align="center">
     <input type="hidden" name="domains" value="clisp.org"/>
     <label for="sbi" style="display: none">Enter your search terms</label>
     <input type="text" name="q" size="50" maxlength="255" id="sbi">
      <xsl:attribute name="value">
       <xsl:apply-templates select="." mode="object.title.markup.textonly"/>
     </xsl:attribute></input>
     <label for="sbb" style="display: none">Submit search form</label>
     <input type="submit" name="sa" value="Google Search" id="sbb"/></td></tr>
   <tr><td nowrap="nowrap" align="center">
     <input type="radio" name="sitesearch" value="" checked="1" id="ss0"/>
     <label for="ss0" title="Search the Web"><small>Web</small></label>
     <input type="radio" name="sitesearch" value="clisp.org" id="ss1"/>
     <label for="ss1" title="Search clisp.org"><small>clisp.org</small></label>
     <input type="hidden" name="client" value="pub-4445255502750357"/>
     <input type="hidden" name="forid" value="1"/>
     <input type="hidden" name="ie" value="UTF-8"/>
     <input type="hidden" name="oe" value="UTF-8"/>
     <input type="hidden" name="cof" value="GALT:#008000;GL:1;DIV:#336699;VLC:663399;AH:center;BGC:FFFFFF;LBGC:000000;ALC:0000FF;LC:0000FF;T:000000;GFNT:0000FF;GIMP:0000FF;LH:48;LW:48;L:http://clisp.cons.org/clisp.png;S:http://clisp.cons.org;FORID:1"/>
     <input type="hidden" name="hl" value="en"/></td></tr></table></form>
 <hr />
</xsl:template>

</xsl:stylesheet>
