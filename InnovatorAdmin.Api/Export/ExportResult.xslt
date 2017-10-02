<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <!-- CDATA wrappers will be removed from all properties except the ones specified here-->
  <xsl:output method="xml" omit-xml-declaration="yes" indent="yes" cdata-section-elements="html_code method_code sqlserver_body stylesheet query class_structure report_query xsl_stylesheet"/>
  <xsl:variable name="systemProperties">|behavior|classification|config_id|created_by_id|created_on|css|current_state|generation|history_id|id|is_current|is_released|keyed_name|release_date|effective_date|locked_by_id|major_rev|managed_by_id|minor_rev|modified_by_id|modified_on|new_version|not_lockable|owned_by_id|permission_id|related_id|sort_order|source_id|state|itemtype|superseded_date|team_id|</xsl:variable>
  <!--<xsl:template match="/">
    <AML>
      <xsl:apply-templates select="*[local-name()='Envelope']"/>
    </AML>
  </xsl:template>
  <xsl:template match="*[local-name()='Envelope']">
    <xsl:apply-templates select="*[local-name()='Body']"/>
  </xsl:template>
  <xsl:template match="*[local-name()='Body']">
    <xsl:apply-templates select="Result"/>
  </xsl:template>-->
  <xsl:template match="//Result[1]">
    <AML>
      <xsl:apply-templates select="Item" mode="first"/>
    </AML>
  </xsl:template>
  <xsl:template match="Item" mode="first">
    <xsl:copy>
      <xsl:copy-of select="@type"/>
      <xsl:copy-of select="@_sql_script"/>
      <xsl:copy-of select="@_float"/>
      <xsl:copy-of select="@id"/>
      <xsl:copy-of select="@where"/>
      <xsl:copy-of select="@_cmf_generated"/>
      <xsl:attribute name="_keyed_name">
        <xsl:value-of select="id/@keyed_name"/>
      </xsl:attribute>
      <xsl:attribute name="action">merge</xsl:attribute>
      <xsl:copy-of select="@dependencyLevel"/>
      <xsl:apply-templates/>
    </xsl:copy>
    <!-- Find system properties that have been modified -->
    <xsl:if test="@type='ItemType'">
      <xsl:apply-templates mode="fix" select="."/>
    </xsl:if>
    <xsl:if test="@type='RelationshipType'">
      <xsl:apply-templates mode="fix" select="relationship_id/Item[@type='ItemType']"/>
    </xsl:if>
    <!-- Check for ItemTypes that have no Views/Forms and delete the autogenerated ones -->
    <xsl:if test="@type='ItemType' and not(Relationships/Item[@type='View'])">
      <Item type="View" action="delete" where="[View].[source_id]='{@id}'"/>
      <Item type="Form" action="delete" where="[Form].[name]='{name}'"/>
    </xsl:if>
    <xsl:if test="boolean(relationship_id/Item) and not(relationship_id/Item/Relationships/Item[@type='View'])">
      <Item type="View" action="delete" where="[View].[source_id]='{relationship_id/Item/@id}'"/>
      <Item type="Form" action="delete" where="[Form].[name]='{relationship_id/Item/name}'"/>
    </xsl:if>
    <!-- Deal with circular Identity=>Member=>Identity references by importing Members after Identities  -->
    <xsl:apply-templates mode="fix" select="Relationships/Item[@type='Member']"/>
    <!-- Deal with circular ItemType=>Morphae=>ItemType references by importing Morphae after ItemTypes  -->
    <xsl:apply-templates mode="fix" select="Relationships/Item[@type='Morphae']"/>
  </xsl:template>
  <xsl:template match="//Item[@type='Property' ]/Relationships/Item[@type='Grid Event']/source_id">
    <xsl:if test="contains($systemProperties,concat('|',../../../name,'|'))">
      <source_id>
        <Item type="Property" action="get" select="id">
          <name>
            <xsl:value-of select="../../../name"/>
          </name>
          <source_id>
            <xsl:value-of select="../../../source_id"/>
          </source_id>
        </Item>
      </source_id>
    </xsl:if>
    <xsl:if test="not(contains($systemProperties,concat('|',../../../name,'|')))">
      <xsl:copy>
        <xsl:copy-of select="@*"/>
        <xsl:apply-templates/>
      </xsl:copy>
    </xsl:if>
  </xsl:template>
  <!-- Replace non-root identities with simple ID references -->
  <xsl:template match="Item[@type='Identity'][name(..)!='' and name(..)!='Result']">
    <xsl:value-of select="@id"/>
  </xsl:template>
  <!-- Remove Members and Morphae - they are added later as part of a fix -->
  <xsl:template match="Item[@type='Member']"/>

  <xsl:template match="Item[@type='Morphae']">
    <Item _is_dependency="1" action="get">
      <xsl:copy-of select="related_id/Item/@*"/>
    </Item>
  </xsl:template>
  <!-- Remove SolutionConfig Export Actions -->
  <xsl:template match="Item[@type='Item Action'][related_id/@keyed_name='SolutionConfig Export']"/>
  <!-- Remove RelationshipTypes from ItemType exports -->
  <xsl:template match="Item[@type='ItemType']/Relationships/Item[@type='RelationshipType']"/>
  <!-- Match related ItemTypes by ID -->
  <xsl:template match="related_id/Item[@type='ItemType']">
    <xsl:value-of select="@id"/>
  </xsl:template>

  <!-- Add action="merge" to all Items that don't match another template -->
  <xsl:template match="Item">
    <xsl:copy>
      <xsl:copy-of select="@type"/>
      <xsl:copy-of select="@id"/>
      <xsl:copy-of select="@where"/>
      <xsl:copy-of select="@_sql_script"/>
      <xsl:copy-of select="@_float"/>
      <xsl:attribute name="action">merge</xsl:attribute>
      <xsl:apply-templates/>
    </xsl:copy>
  </xsl:template>

  <!-- Replace full item data with ID references when exporting an ItemType -->
  <xsl:template match="Item[@type='ItemType']/Relationships/Item/related_id/Item[@type='Form' or @type='Action' or @type='Life Cycle Map' or @type='Permission' or @type='Report']">
    <xsl:value-of select="@id"/>
  </xsl:template>
  <xsl:template match="Item[@type='Activity Template Transition']//Item[@type='Life Cycle Transition']">
    <xsl:value-of select="@id"/>
  </xsl:template>

  <!-- Eliminate system and is_keyed properties and from ItemType definitions -->
  <xsl:template match="Item[@type='Property'][is_keyed='1']"/>
  <xsl:template match="Item[@type='Property'][name='behavior']"/>
  <xsl:template match="Item[@type='Property'][name='classification']"/>
  <xsl:template match="Item[@type='Property'][name='config_id']"/>
  <xsl:template match="Item[@type='Property'][name='created_by_id']"/>
  <xsl:template match="Item[@type='Property'][name='created_on']"/>
  <xsl:template match="Item[@type='Property'][name='css']"/>
  <xsl:template match="Item[@type='Property'][name='current_state']"/>
  <xsl:template match="Item[@type='Property'][name='generation']"/>
  <xsl:template match="Item[@type='Property'][name='history_id']"/>
  <xsl:template match="Item[@type='Property'][name='id']"/>
  <xsl:template match="Item[@type='Property'][name='is_current']"/>
  <xsl:template match="Item[@type='Property'][name='is_released']"/>
  <xsl:template match="Item[@type='Property'][name='keyed_name']"/>
  <xsl:template match="Item[@type='Property'][name='locked_by_id']"/>
  <xsl:template match="Item[@type='Property'][name='major_rev']"/>
  <xsl:template match="Item[@type='Property'][name='managed_by_id']"/>
  <xsl:template match="Item[@type='Property'][name='minor_rev']"/>
  <xsl:template match="Item[@type='Property'][name='modified_by_id']"/>
  <xsl:template match="Item[@type='Property'][name='modified_on']"/>
  <xsl:template match="Item[@type='Property'][name='new_version']"/>
  <xsl:template match="Item[@type='Property'][name='not_lockable']"/>
  <xsl:template match="Item[@type='Property'][name='owned_by_id']"/>
  <xsl:template match="Item[@type='Property'][name='permission_id']"/>
  <xsl:template match="Item[@type='Property'][name='related_id']"/>
  <xsl:template match="Item[@type='Property'][name='sort_order']"/>
  <xsl:template match="Item[@type='Property'][name='source_id']"/>
  <xsl:template match="Item[@type='Property'][name='state']"/>
  <xsl:template match="Item[@type='Property'][name='itemtype']"/>
  <xsl:template match="Item[@type='Property'][name='effective_date'][../../is_versionable='1']"/>
  <xsl:template match="Item[@type='Property'][name='release_date'][../../is_versionable='1']"/>
  <xsl:template match="Item[@type='Property'][name='superseded_date'][../../is_versionable='1']"/>
  <xsl:template match="Item[@type='Property'][name='team_id']"/>

  <!-- Eliminate the system properties from all ItemTypes -->
  <xsl:template match="cache_query"/>
  <xsl:template match="config_id"/>
  <xsl:template match="core"/>
  <xsl:template match="Item[@type!='Field' and @type!='Body']/css"/>
  <xsl:template match="generation"/>
  <xsl:template match="history_id"/>
  <xsl:template match="id"/>
  <xsl:template match="is_cached"/>
  <xsl:template match="is_current"/>
  <xsl:template match="keyed_name"/>
  <xsl:template match="locked_by_id"/>
  <xsl:template match="new_version"/>
  <xsl:template match="itemtype"/>
  <xsl:template match="Item[@type='Property' and data_type!='item' ]/item_behavior"/>
  <xsl:template match="Relationships/Item/source_id" />

  <!-- Custom property -->
  <xsl:template match="Item[@type='Method']/checksum"/>

  <!-- Eliminate current_value property from Sequences -->
  <xsl:template match="Item[@type='Sequence']/current_value"/>

  <!-- Eliminate execution_count property from SQL items -->
  <xsl:template match="Item[@type='SQL']/execution_count"/>

  <!-- Eliminate meaningless classificaton properties -->
  <xsl:template match="classification[text() = '' or text() = '/*']"/>

  <!-- Remove empty Relationships tags -->
  <xsl:template match="Relationships[count(*)=0]"/>

  <!-- Second ItemType tag to deal with is_keyed and modified system properties -->
  <xsl:template mode="fix" match="Item[@type='ItemType']">
    <xsl:variable name="modifiedSystemProps" select="Relationships/Item[@type='Property'][name='behavior'][string(label)!='' or string(data_type)!='list' or (stored_length and string(stored_length)!='64') or string(column_alignment)!='left' or string(is_hidden)!='1' or string(is_hidden2)!='1' or string(column_width)!='' or string(readonly)!='0' or string(is_keyed)!='0' or string(order_by)!=''] |
                                  Relationships/Item[@type='Property'][name='classification'][string(label)!='Classification' or string(data_type)!='string' or string(stored_length)!='512' or string(column_alignment)!='left' or string(is_hidden)!='1' or string(is_hidden2)!='1' or string(column_width)!='' or string(readonly)!='0' or string(is_keyed)!='0' or string(order_by)!=''] |
                                  Relationships/Item[@type='Property'][name='config_id'][string(label)!='' or string(data_type)!='item' or string(stored_length)!='' or string(column_alignment)!='left' or string(is_hidden)!='1' or string(is_hidden2)!='1' or string(column_width)!='' or string(readonly)!='1' or string(is_keyed)!='0' or string(order_by)!=''] |
                                  Relationships/Item[@type='Property'][name='created_by_id'][string(label)!='' or string(data_type)!='item' or string(stored_length)!='' or string(column_alignment)!='left' or string(is_hidden)!='1' or string(is_hidden2)!='1' or string(column_width)!='' or string(readonly)!='1' or string(is_keyed)!='0' or string(order_by)!=''] |
                                  Relationships/Item[@type='Property'][name='created_on'][string(label)!='' or string(data_type)!='date' or string(stored_length)!='' or string(column_alignment)!='left' or string(is_hidden)!='1' or string(is_hidden2)!='1' or string(column_width)!='' or string(readonly)!='1' or string(is_keyed)!='0' or string(order_by)!=''] |
                                  Relationships/Item[@type='Property'][name='css'][string(label)!='' or string(data_type)!='text' or string(stored_length)!='' or string(column_alignment)!='left' or string(is_hidden)!='1' or string(is_hidden2)!='1' or string(column_width)!='' or string(readonly)!='0' or string(is_keyed)!='0' or string(order_by)!=''] |
                                  Relationships/Item[@type='Property'][name='current_state'][string(label)!='' or string(data_type)!='item' or string(stored_length)!='' or string(column_alignment)!='left' or string(is_hidden)!='1' or string(is_hidden2)!='1' or string(column_width)!='' or string(readonly)!='1' or string(is_keyed)!='0' or string(order_by)!=''] |
                                  Relationships/Item[@type='Property'][name='generation'][string(label)!='' or string(data_type)!='integer' or string(stored_length)!='' or string(column_alignment)!='left' or string(is_hidden)!='1' or string(is_hidden2)!='1' or string(column_width)!='' or string(readonly)!='1' or string(is_keyed)!='0' or string(order_by)!=''] |
                                  Relationships/Item[@type='Property'][name='history_id'][string(label)!='History Id' or string(data_type)!='item' or string(stored_length)!='' or string(column_alignment)!='left' or string(is_hidden)!='1' or string(is_hidden2)!='1' or string(column_width)!='' or string(readonly)!='0' or string(is_keyed)!='0' or string(order_by)!=''] |
                                  Relationships/Item[@type='Property'][name='id'][string(label)!='' or string(data_type)!='item' or string(stored_length)!='' or string(column_alignment)!='left' or string(is_hidden)!='1' or string(is_hidden2)!='1' or string(column_width)!='' or string(readonly)!='1' or string(is_keyed)!='0' or string(order_by)!=''] |
                                  Relationships/Item[@type='Property'][name='is_current'][string(label)!='' or string(data_type)!='boolean' or string(stored_length)!='' or string(column_alignment)!='left' or string(is_hidden)!='1' or string(is_hidden2)!='1' or string(column_width)!='' or string(readonly)!='1' or string(is_keyed)!='0'] |
                                  Relationships/Item[@type='Property'][name='is_released'][string(label)!='Released' or string(data_type)!='boolean' or string(stored_length)!='' or string(column_alignment)!='left' or string(is_hidden)!='1' or string(is_hidden2)!='1' or string(column_width)!='' or string(readonly)!='1' or string(is_keyed)!='0' or string(order_by)!=''] |
                                  Relationships/Item[@type='Property'][name='keyed_name'][string(label)!='' or string(data_type)!='string' or string(stored_length)!='128' or string(column_alignment)!='left' or string(is_hidden)!='1' or string(is_hidden2)!='1' or string(column_width)!='' or string(readonly)!='0' or string(is_keyed)!='0' or string(order_by)!=''] |
                                  Relationships/Item[@type='Property'][name='locked_by_id'][string(label)!='' or string(data_type)!='item' or string(stored_length)!='' or string(column_alignment)!='left' or string(is_hidden)!='1' or string(is_hidden2)!='1' or string(column_width)!='' or string(readonly)!='1' or string(is_keyed)!='0' or string(order_by)!=''] |
                                  Relationships/Item[@type='Property'][name='major_rev'][string(label)!='' or string(data_type)!='string' or string(stored_length)!='8' or string(column_alignment)!='left' or string(is_hidden)!='1' or string(is_hidden2)!='1' or string(column_width)!='' or string(readonly)!='0' or string(is_keyed)!='0' or string(order_by)!=''] |
                                  Relationships/Item[@type='Property'][name='managed_by_id'][string(label)!='' or string(data_type)!='item' or string(stored_length)!='' or string(column_alignment)!='left' or string(is_hidden)!='1' or string(is_hidden2)!='1' or string(column_width)!='' or string(readonly)!='0' or string(is_keyed)!='0' or string(order_by)!=''] |
                                  Relationships/Item[@type='Property'][name='minor_rev'][string(label)!='' or string(data_type)!='string' or string(stored_length)!='8' or string(column_alignment)!='left' or string(is_hidden)!='1' or string(is_hidden2)!='1' or string(column_width)!='' or string(readonly)!='0' or string(is_keyed)!='0' or string(order_by)!=''] |
                                  Relationships/Item[@type='Property'][name='modified_by_id'][string(label)!='' or string(data_type)!='item' or string(stored_length)!='' or string(column_alignment)!='left' or string(is_hidden)!='1' or string(is_hidden2)!='1' or string(column_width)!='' or string(readonly)!='1' or string(is_keyed)!='0' or string(order_by)!=''] |
                                  Relationships/Item[@type='Property'][name='modified_on'][string(label)!='' or string(data_type)!='date' or string(stored_length)!='' or string(column_alignment)!='left' or string(is_hidden)!='1' or string(is_hidden2)!='1' or string(column_width)!='' or string(readonly)!='1' or string(is_keyed)!='0' or string(order_by)!=''] |
                                  Relationships/Item[@type='Property'][name='new_version'][string(label)!='' or string(data_type)!='boolean' or string(stored_length)!='' or string(column_alignment)!='left' or string(is_hidden)!='1' or string(is_hidden2)!='1' or string(column_width)!='' or string(readonly)!='1' or string(is_keyed)!='0' or string(order_by)!=''] |
                                  Relationships/Item[@type='Property'][name='not_lockable'][string(label)!='Not Lockable' or string(data_type)!='boolean' or string(stored_length)!='' or string(column_alignment)!='left' or string(is_hidden)!='1' or string(is_hidden2)!='1' or string(column_width)!='' or string(readonly)!='1' or string(is_keyed)!='0' or string(order_by)!=''] |
                                  Relationships/Item[@type='Property'][name='owned_by_id'][string(label)!='' or string(data_type)!='item' or string(stored_length)!='' or string(column_alignment)!='left' or string(is_hidden)!='1' or string(is_hidden2)!='1' or string(column_width)!='' or string(readonly)!='0' or string(is_keyed)!='0' or string(order_by)!=''] |
                                  Relationships/Item[@type='Property'][name='permission_id'][string(label)!='' or string(data_type)!='item' or string(stored_length)!='' or string(column_alignment)!='left' or string(is_hidden)!='1' or string(is_hidden2)!='1' or string(column_width)!='' or string(readonly)!='1' or string(is_keyed)!='0' or string(order_by)!=''] |
                                  Relationships/Item[@type='Property'][name='related_id'][string(label)!='' or string(data_type)!='item' or string(stored_length)!='' or string(column_alignment)!='left' or string(is_hidden)!='0' or string(is_hidden2)!='1' or string(column_width)!='' or string(readonly)!='0' or string(is_keyed)!='0' or string(order_by)!=''] |
                                  Relationships/Item[@type='Property'][name='sort_order'][string(label)!='' or string(data_type)!='integer' or string(stored_length)!='' or string(column_alignment)!='left' or string(is_hidden)!='1' or string(is_hidden2)!='1' or string(column_width)!='' or string(readonly)!='0' or string(is_keyed)!='0' or string(order_by)!=''] |
                                  Relationships/Item[@type='Property'][name='source_id'][string(label)!='' or string(data_type)!='item' or string(stored_length)!='' or string(column_alignment)!='left' or string(is_hidden)!='1' or string(is_hidden2)!='1' or string(column_width)!='' or string(readonly)!='0' or string(is_keyed)!='0' or string(order_by)!=''] |
                                  Relationships/Item[@type='Property'][name='state'][string(label)!='' or string(data_type)!='string' or string(stored_length)!='32' or string(column_alignment)!='left' or string(is_hidden)!='1' or string(is_hidden2)!='1' or string(column_width)!='' or string(readonly)!='1' or string(is_keyed)!='0' or string(order_by)!=''] |
                                  Relationships/Item[@type='Property'][name='effective_date'][../../is_versionable='1'][string(label)!='Effective Date' or string(data_type)!='date' or string(stored_length)!='' or string(column_alignment)!='left' or string(is_hidden)!='1' or string(is_hidden2)!='1' or string(column_width)!='' or string(readonly)!='0' or string(is_keyed)!='0' or string(order_by)!=''] |
                                  Relationships/Item[@type='Property'][name='release_date'][../../is_versionable='1'][string(label)!='Release Date' or string(data_type)!='date' or string(stored_length)!='' or string(column_alignment)!='left' or string(is_hidden)!='1' or string(is_hidden2)!='1' or string(column_width)!='' or string(readonly)!='1' or string(is_keyed)!='0' or string(order_by)!=''] |
                                  Relationships/Item[@type='Property'][name='superseded_date'][../../is_versionable='1'][string(label)!='Superseded Date' or string(data_type)!='date' or string(stored_length)!='' or string(column_alignment)!='left' or string(is_hidden)!='0' or string(is_hidden2)!='0' or string(column_width)!='' or string(readonly)!='1' or string(is_keyed)!='0' or string(order_by)!=''] |
                                  Relationships/Item[@type='Property'][name='itemtype'][string(label)!='ItemType' or string(data_type)!='list' or string(stored_length)!='' or string(column_alignment)!='left' or string(is_hidden)!='1' or string(is_hidden2)!='1' or string(column_width)!='' or string(readonly)!='0' or string(is_keyed)!='0' or string(order_by)!=''] |
                                  Relationships/Item[@type='Property'][name='team_id'][string(label)!='Team' or string(data_type)!='item' or string(stored_length)!='' or string(column_alignment)!='left' or string(is_hidden)!='1' or string(is_hidden2)!='1' or string(column_width)!='' or string(readonly)!='0' or string(is_keyed)!='0' or string(order_by)!=''] |
                                  Relationships/Item[@type='Property'][contains($systemProperties,concat('|',name,'|'))][Relationships[child::node()]]"/>

    <xsl:if test="count(Relationships/Item[@type='Property'][is_keyed='1'][not(contains($systemProperties,concat('|',name,'|')))]) > 0 or count($modifiedSystemProps) > 0">
      <xsl:copy>
        <xsl:copy-of select="@type"/>
        <xsl:copy-of select="@id"/>
        <xsl:attribute name="action">edit</xsl:attribute>
        <xsl:attribute name="_scriptType">1</xsl:attribute>
        <Relationships>
          <xsl:apply-templates mode="fix" select="Relationships/Item[@type='Property'][is_keyed='1'][not(contains($systemProperties,concat('|',name,'|')))]"/>
          <xsl:apply-templates mode="fix" select="$modifiedSystemProps"/>
        </Relationships>
      </xsl:copy>
    </xsl:if>
  </xsl:template>
  <!-- Fix for system properties that have been modified  -->
  <!-- Properties with is_keyed='1' add with modified system properties, because there may be a situation such as in RT Field Event(source_id, related_id and field_event in a general index and this properties must be imported together) -->
  <xsl:template mode="fix" match="Item[@type='Property']">
    <xsl:copy>
      <xsl:copy-of select="@type"/>
      <xsl:choose>
        <xsl:when test="contains($systemProperties,concat('|',name,'|'))">
          <xsl:attribute name="action">edit</xsl:attribute>
          <xsl:attribute name="where">
            <xsl:text>source_id='</xsl:text>
            <xsl:value-of select="source_id"/>
            <xsl:text>' and name='</xsl:text>
            <xsl:value-of select="name"/>
            <xsl:text>'</xsl:text>
          </xsl:attribute>
        </xsl:when>
        <xsl:when test="is_keyed='1'">
          <xsl:copy-of select="@id"/>
          <xsl:attribute name="action">merge</xsl:attribute>
        </xsl:when>
      </xsl:choose>
      <xsl:apply-templates/>
    </xsl:copy>
  </xsl:template>
  <!-- Fix to put Members at the end  -->
  <xsl:template mode="fix" match="Item[@type='Member']">
    <xsl:copy>
      <xsl:copy-of select="@type"/>
      <xsl:copy-of select="@id"/>
      <xsl:attribute name="action">merge</xsl:attribute>
      <xsl:copy-of select="source_id"/>
      <xsl:apply-templates/>
    </xsl:copy>
  </xsl:template>
  <!-- Fix for Morphae  -->
  <xsl:template mode="fix" match="Item[@type='Morphae']">
    <Item type="ItemType" id="{../../@id}" action="edit" >
      <xsl:attribute name="_scriptType">2.<xsl:value-of select="related_id" /></xsl:attribute>
      <Relationships>
        <xsl:copy>
          <xsl:copy-of select="@type"/>
          <xsl:copy-of select="@id"/>
          <xsl:attribute name="action">merge</xsl:attribute>
          <xsl:copy-of select="source_id"/>
          <xsl:apply-templates/>
        </xsl:copy>
      </Relationships>
    </Item>
  </xsl:template>
  <!-- Copy all nodes that don't match another template (but remove CDATA wrappers) -->
  <xsl:template match="*">
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:apply-templates/>
    </xsl:copy>
  </xsl:template>
</xsl:stylesheet>
