<cfcomponent output="false" displayName="Page DAO" hint="Does DAO for Pages">

	<cfset variables.dsn = "">
	
	<cffunction name="init" access="public" returnType="PageDAO" output="false">
		<cfargument name="dsn" type="string" required="true">
		
		<cfset variables.dsn = arguments.dsn>
		
		<cfreturn this>
	</cffunction>

	<cffunction name="create" access="public" returnType="PageBean" output="false">
		<cfargument name="pBean" type="PageBean" required="true">
		
		<cfquery datasource="#dsn#">
			insert into page(pageid, projectid, path,body,datetimecreated,userid,version,summary)
			values(
				<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.pBean.getpageID()#" maxlength="35">,
				<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.pBean.getprojectID()#" maxlength="35">,
				<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.pBean.getPath()#" maxlength="255">,
				<cfqueryparam cfsqltype="cf_sql_longvarchar" value="#arguments.pBean.getBody()#">,
				<cfqueryparam cfsqltype="cf_sql_timestamp" value="#arguments.pBean.getDateTimeCreated()#">,
				<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.pBean.getuserid()#" maxlength="255">,
				<cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.pBean.getVersion()#">,
				<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.pBean.getSummary()#" maxlength="255">
				)
		</cfquery>

		<cfreturn pBean>
	</cffunction>

	<cffunction name="new" access="public" returnType="PageBean" output="false">
		<cfreturn createObject("component", "PageBean")>
	</cffunction>
		
	<cffunction name="read" access="public" returnType="PageBean" output="false">
		<cfargument name="id" type="uuid" required="true">
		<cfset var pBean = createObject("component", "PageBean")>
		<cfset var getit = "">
		
		<cfquery name="getit" datasource="#variables.dsn#">
			select 	pageid, projectid, path, body, datetimecreated, userid, version, summary
			from	page
			where	pageid = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.id#" maxlength="35">
		</cfquery>
		
		<cfif getit.recordCount>
			<cfset pBean.setpageID(getit.pageid)>
			<cfset pBean.setprojectID(getit.projectid)>
			<cfset pBean.setPath(getit.path)>
			<cfset pBean.setBody(getit.body)>
			<cfset pBean.setDateTimeCreated(getit.datetimecreated)>
			<cfset pBean.setuserid(getit.userid)>
			<cfset pBean.setVersion(getit.version)>
			<cfset pBean.setSummary(getit.summary)>
		</cfif>
		
		<cfreturn pBean>
	</cffunction>


</cfcomponent>