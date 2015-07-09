<cfcomponent output="false" displayName="Page Bean" hint="Manages a page instance.">

	<cfset variables.instance = structNew() />
	<cfset variables.instance.pageid = 0 />
	<cfset variables.instance.projectid = "">
	<cfset variables.instance.path = "" />
	<cfset variables.instance.body = "" />
	<cfset variables.instance.datetimecreated = "" />
	<cfset variables.instance.userid = "" />
	<cfset variables.instance.version = "" />
	<cfset variables.instance.summary = "" />

	<cffunction name="setpageID" returnType="void" access="public" output="false">
		<cfargument name="pageid" type="string" required="true">
		<cfset variables.instance.pageid = arguments.pageid>
	</cffunction>

	<cffunction name="getpageID" returnType="string" access="public" output="false">
		<cfreturn variables.instance.pageid>
	</cffunction>
	
	<cffunction name="setprojectID" returnType="void" access="public" output="false">
		<cfargument name="projectid" type="string" required="true">
		<cfset variables.instance.projectid = arguments.projectid>
	</cffunction>

	<cffunction name="getprojectid" returnType="string" access="public" output="false">
		<cfreturn variables.instance.projectid>
	</cffunction>
	
	<cffunction name="setPath" returnType="void" access="public" output="false">
		<cfargument name="path" type="string" required="true">
		<cfset variables.instance.path = arguments.path>
	</cffunction>
  
	<cffunction name="getPath" returnType="string" access="public" output="false">
		<cfreturn variables.instance.path>
	</cffunction>

	<cffunction name="setBody" returnType="void" access="public" output="false">
		<cfargument name="body" type="string" required="true">
		<cfset variables.instance.body = arguments.body>
	</cffunction>
  
	<cffunction name="getBody" returnType="string" access="public" output="false">
		<cfreturn variables.instance.body>
	</cffunction>
	
	<cffunction name="setDateTimeCreated" returnType="void" access="public" output="false">
		<cfargument name="datetimecreated" type="string" required="true">
		<cfset variables.instance.datetimecreated = arguments.datetimecreated>
	</cffunction>
  
	<cffunction name="getDateTimeCreated" returnType="string" access="public" output="false">
		<cfreturn variables.instance.datetimecreated>
	</cffunction>
	
	<cffunction name="setUserID" returnType="void" access="public" output="false">
		<cfargument name="userid" type="string" required="true">
		<cfset variables.instance.userid = arguments.userid>
	</cffunction>
  
	<cffunction name="getUserid" returnType="string" access="public" output="false">
		<cfreturn variables.instance.userid>
	</cffunction>
	
	<cffunction name="setVersion" returnType="void" access="public" output="false">
		<cfargument name="version" type="string" required="true">
		<cfset variables.instance.version = arguments.version>
	</cffunction>
  
	<cffunction name="getVersion" returnType="string" access="public" output="false">
		<cfreturn variables.instance.version>
	</cffunction>
	
	<cffunction name="setSummary" returnType="void" access="public" output="false">
		<cfargument name="summary" type="string" required="true">
		<cfset variables.instance.summary = arguments.summary>
	</cffunction>
  
	<cffunction name="getSummary" returnType="string" access="public" output="false">
		<cfreturn variables.instance.summary>
	</cffunction>

	<cffunction name="validate" returnType="array" access="public" output="false">
		<cfset var errors = arrayNew(1)>
		
		<cfif not len(trim(getPath()))>
			<cfset arrayAppend(errors,"Path cannot be blank.")>
		</cfif>

		<cfif not len(trim(getBody()))>
			<cfset arrayAppend(errors,"Body cannot be blank.")>
		</cfif>
		  
		<cfreturn errors>
	</cffunction>
	
	<cffunction name="getInstance" returnType="struct" access="public" output="false">
		<cfreturn duplicate(variables.instance)>
	</cffunction>

</cfcomponent>	