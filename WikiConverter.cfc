<cfcomponent output="false">
	<cffunction name="init" access="public" output="false" returntype="WikiConverter">
		<!--- javaloader is required for this component to work --->
		<cfset var loadPaths = ArrayNew(1) />
		<cfset loadPaths[1] = expandPath("includes/htmlparser.jar") />
		<cfset loadPaths[2] = expandPath("includes/bliki.jar") />
		<cfset variables.javaloader = createObject("component", "skweegee.includes.javaloader.JavaLoader").init(loadPaths) />
		
		<!--- these are needed later --->
		<cfset variables.WikiModel = "" />
		<cfset variables.HTML2WikipediaExtractor = "" />
		<cfset variables.imageBaseURL = "" />
		<cfset variables.linkBaseURL = "" />
		
		<cfreturn this />
	</cffunction>
	
	<cffunction name="WikiToHtml" access="public" output="false" returntype="string">
		<cfargument name="imageBaseURL" type="string" required="true" />
		<cfargument name="linkBaseURL" type="string" required="true" />
		<cfargument name="rawWikiText" type="string" required="true" />
		
		<cfif isSimpleValue(variables.WikiModel) or (arguments.imageBaseURL neq variables.imageBaseURL) or (arguments.linkBaseURL neq variables.linkBaseURL)>
			<cfset variables.imageBaseURL = arguments.imageBaseURL />
			<cfset variables.linkBaseURL = arguments.linkBaseURL />
			<cfset variables.WikiModel = variables.javaloader.create("info.bliki.wiki.filter.WikiModel").init(variables.imageBaseURL,variables.linkBaseURL) />
		</cfif>

		<cfreturn variables.WikiModel.render(arguments.rawWikiText) />
	</cffunction>
	
	<cffunction name="HtmlToWiki" access="public" output="false" returntype="string">
		<cfargument name="inputHTML" type="string" required="true" />
		
		<cfif isSimpleValue(variables.HTML2WikipediaExtractor)>
			<cfset variables.HTML2WikipediaExtractor = variables.javaloader.create("info.bliki.html.HTML2WikipediaExtractor").init() />
		</cfif>
		
		<cfset variables.HTML2WikipediaExtractor.setInputHTML(arguments.inputHTML) />
		<cfreturn variables.HTML2WikipediaExtractor.extractStrings() />
	</cffunction>
</cfcomponent>