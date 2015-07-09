<cfcomponent displayName="Page Gateway" output="false" hint="Gateway CFC for Pages">

	<cfset variables.dsn = "">
	
	<cffunction name="init" access="public" returnType="PageGateway" output="false">
		<cfargument name="dsn" type="string" required="true">
		
		<cfset variables.dsn = arguments.dsn>
		<cfset variables.pageDAO = createObject("component", "PageDAO").init(variables.dsn)>
		<cfset variables.utils = createObject("component", "Utils")>
		<cfset variables.pageRender = createObject("component", "PageRender").init()>
		
		<cfreturn this>
	</cffunction>	
	
	<cffunction name="getPage" access="public" returnType="PageBean" output="false"
				hint="Method to get the 'current' page, which is based on cgi.path_info.">
		<cfargument name="thisPage" type="string" required="false" default="">
		<cfargument name="version" type="numeric" required="false" default="0">
		<cfset var defaultPage = "Main">
		<cfset var pLookup = "">
		<cfset var vLookup = "">
		<cfset var pob = "">
		
		<!--- current page is either default, Main, or based on url.path, or cgi.path_info --->
		<!--- 11/2/2006 Russ Johnson (russ@angry-fly.com) Making a change to allow the page to be
				based on cgi.query_string instead of path_info so we get the page attribute --->
		<!--- <cfif not len(arguments.thisPage)>
			<cfif len(cgi.path_info) and cgi.path_info neq cgi.script_name>
				<cfset arguments.thisPage = cgi.path_info>
				<!--- should always be /XXXX.XXXX --->
				<cfif left(arguments.thisPage,1) is "/">
					<cfset arguments.thisPage = right(arguments.thisPage, len(arguments.thisPage)-1)>
				</cfif>
			<cfelse>
				<cfset arguments.thisPage = defaultPage>
			</cfif>
		</cfif> --->
		
		<cfif not len(arguments.thisPage)>
			<cfif len(attributes.page)>
				<cfset arguments.thisPage = attributes.page>
				<!--- should always be /XXXX.XXXX --->
				<cfif left(arguments.thisPage,1) is "/">
					<cfset arguments.thisPage = right(arguments.thisPage, len(arguments.thisPage)-1)>
				</cfif>
			<cfelse>
				<cfset arguments.thisPage = defaultPage>
			</cfif>
		</cfif>

		<cfif arguments.version is 0>
			<cfquery name="vLookup" datasource="#variables.dsn#">
			select	max(version) as maxversion
			from	page
			where	path = <cfqueryparam cfsqltype="cf_sql_varchar" maxlength="255" value="#thisPage#">
			</cfquery>
			<cfif vLookup.recordCount and isNumeric(vLookup.maxversion)>
				<cfset arguments.version = vLookup.maxversion>
			</cfif>
		</cfif>

		<cfquery name="pLookup" datasource="#variables.dsn#">
			select	pageid
			from	page
			where	path = <cfqueryparam cfsqltype="cf_sql_varchar" maxlength="255" value="#arguments.thisPage#">
			and		version = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.version#">
		</cfquery>
					
		<cfif pLookup.recordCount>
			<cfreturn variables.pageDAO.read(pLookup.pageid)>
		<cfelse>
			<cfset pob = variables.pageDAO.new()>
			<cfset pob.setPath(arguments.thisPage)>
			<cfreturn pob>
		</cfif>
			
	</cffunction>

	<cffunction name="getPageHistory" access="public" returnType="query" output="false"
				hint="Returns the history of a page.">
		<cfargument name="pageBean" type="PageBean" required="true">
		<cfset var q = "">
		
		<cfquery name="q" datasource="#variables.dsn#">
		select		pageid, path, projectid, body, datetimecreated, userid, version, summary
		from		page
		where		path = <cfqueryparam cfsqltype="cf_sql_varchar" maxlength="255" value="#arguments.pageBean.getPath()#">
		order by 	version asc
		</cfquery>
		
		<cfreturn q>
	</cffunction>

	<cffunction name="getPageIndex" access="public" returnType="query" output="false"
				hint="Returns a list of all pages with version, lastmod, etc.">
		<cfset var q = "">
		<cfset var getMaxVersion = "">
		<cfset var getID = "">
		<cfset var getInfo = "">
		
		<cfquery name="q" datasource="#variables.dsn#">
		select     pageid, projectid, path, body, datetimecreated, userid, version, summary
		from       page p1
		where     (version =
                  (select     max(p2.version)
                   from          pages p2
                   where      p1.path = p2.path))		
		order by   p1.path asc		
		</cfquery>
				
		<cfreturn q>
	</cffunction>
	
	<cffunction name="getRenderInstructions" access="public" returnType="string" output="false"
				hint="Call the render object to generate documentation.">
		<cfreturn variables.pageRender.instructions()>		
	</cffunction>
	
	<cffunction name="render" access="public" returnType="string" output="false"
				hint="I do the heavy lifting of transforming a page body into the display.">
		<cfargument name="pageBean" type="PageBean" required="true">
		<cfargument name="webpath" type="string" required="true">

		<!--- I'm not sure why I'm keeping this here, since it just passed off to render, but I kind of like the abstraction --->
		<cfreturn variables.pageRender.render(pageBean, webpath)>		
	</cffunction>
	
	<cffunction name="search" access="public" returnType="query" output="false"
				hint="Search pages.">
		<cfargument name="searchterms" type="string" required="true">
		
		<!--- first, we need to get the IDs of the max version of each page --->
		<cfset var search = "">
		
		<cfquery name="search" datasource="#variables.dsn#">
		select     pageid, projectid path, body, datetimecreated, userid, version, summary
		from       page p1
		where     (version =
                  (select     max(p2.version)
                   from          page p2
                   where      p1.path = p2.path))		
		and (body like <cfqueryparam cfsqltype="cf_sql_longvarchar" value="%#arguments.searchterms#%">	
		or summary like <cfqueryparam cfsqltype="cf_sql_varchar" value="%#arguments.searchterms#%">
		or userid like <cfqueryparam cfsqltype="cf_sql_varchar" value="%#arguments.searchterms#%">
		)
		order by   p1.path asc		
		</cfquery>

		<cfreturn search>
	</cffunction>	

</cfcomponent>