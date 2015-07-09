<!---
	Name         : C:\projects\tikiwiki\wwwroot\canvas\model\PageRender.cfc
	Author       : Raymond Camden 
	Created      : A long time ago, in a place far, far away....
	Last Updated : 4/4/06
	History      : Changed priority on WikiTerms to be 1, so it runs after Link rule. (rkc 2/17/06)
				   links were throwing an error if they started at position 1. Thanks to Rob Gonda (rkc 4/4/06)
--->

<cfcomponent displayName="Page Render" output="true" hint="This CFC just handles rendering functions.">

	<cfset variables.renderMethods = structNew()>
	<cfset variables.variableMethods = structNew()>
	
	<cffunction name="init" access="public" returnType="PageRender" output="true">
		<cfset var key = "">
		<cfset var md = "">
		<cfset var s = "">
		<cfset var varDir = getDirectoryFromPath(GetCurrentTemplatePath()) & "/variablecomponents/">
		<cfset var varCFCs = "">
		<cfset var cfcName = "">

		<cfset variables.utils = createObject("component", "Utils")>

		<!--- get my methods --->
		<cfloop item="key" collection="#this#">
			<cfif isCustomFunction(this[key])>
				<!--- see if method if render_ --->
				<cfif findNoCase("render_", key) is 1>
					<cfset md = getMetaData(this[key])>
					<cfif not structKeyExists(md, "priority") or not isNumeric(md.priority)>
						<cfset md.priority = 1>
					</cfif>
					<!--- just copy name and priority --->
					<cfset s = structNew()>
					<cfset s.name = md.name>
					<cfset s.priority = md.priority>
					<cfset s.instructions = md.hint>
					<cfset variables.renderMethods[s.name] = duplicate(s)>					
				</cfif>
			</cfif>
		</cfloop>

		<!--- get my kids --->
		<cfdirectory action="list" name="varCFCs" directory="#varDir#" filter="*.cfc">
		
		<cfloop query="varCFCs">
			<cfset cfcName = listDeleteAt(name, listLen(name, "."), ".")>
			
			<!--- store the name --->
			<cfset variables.variableMethods[cfcName] = structNew()>
			<!--- create an instance of the CFC. It better have a render method! --->
			<cfset variables.variableMethods[cfcName].cfc = createObject("component", "variablecomponents.#cfcName#")>
			<cfset md = getMetaData(variables.variableMethods[cfcName].cfc)>
			<cfif structKeyExists(md, "hint")>
				<cfset variables.variableMethods[cfcName].instructions = md.hint>
			</cfif>
			
		</cfloop>
		
		<cfreturn this>
	</cffunction>	
	
	<cffunction name="instructions" access="public" returnType="string" output="false"
				hint="Generate dynamic instructions.">		
		<cfset var sorted = "">
		<cfset var x = "">
		<cfset var result = "<ul>">

		<!--- Start parsing... --->
		<!--- sort the render methods --->
		<cfset sorted = structSort(variables.rendermethods, "numeric", "asc", "priority")>

		<cfloop index="x" from="1" to="#arrayLen(sorted)#">
			<cfset result = result & "<li>" & rendermethods[sorted[x]].instructions & "</li>">
		</cfloop>		


		<cfloop item="x" collection="#variables.variableMethods#">
			<cfif structKeyExists(variables.variableMethods[x], "instructions")>
				<cfset result = result & "<li>" & variables.variableMethods[x].instructions & "</li>">
			</cfif>
		</cfloop>		

		<cfset result = result & "</ul>">
		
		<cfreturn result>		

	</cffunction>
	
	<cffunction name="render" access="public" returnType="string" output="true"
				hint="I do the heavy lifting of transforming a page body into the display.">
		<cfargument name="bodyContent" type="string" required="true">
		<cfargument name="webPath" type="string" required="false" default="Main">
		<cfargument name="pageBean" type="pageBean" required="false">
		
		<cfset var body = arguments.bodyContent>
		<cfset var sorted = "">
		<cfset var x = "">
		<cfset var tokens = "">
		<cfset var token = "">
		<cfset var cfcName = "">
		<cfset var result = "">
		
		<cfif not len(body)>
			<cfsavecontent variable="body">			
			<cfoutput>
				<h1>No Page</h1>
				<p>This page you are trying to view doesn't exist yet.<br>
				<a href="index.cfm?do=cWiki.editPage&page=#arguments.webPath#&new=true">Click Here</a> if you would
				like to create this page and add content to it.</p>
			</cfoutput>
			</cfsavecontent>
			<cfreturn body>
		</cfif>

		<!--- Start parsing... --->
		<!--- sort the render methods --->
		<cfset sorted = structSort(variables.rendermethods, "numeric", "asc", "priority")>
		
		<cfloop index="x" from="1" to="#arrayLen(sorted)#">
			<cfinvoke method="#sorted[x]#" string="#body#" webpath="#arguments.webPath#" returnVariable="body">
		</cfloop>		

		<!--- now look for {variables} --->
		<cfset tokens = variables.utils.reFindAll("{.*?}", body)>
		<cfif tokens.pos[1] is not 0>
			<cfloop index="x" from="#arrayLen(tokens.pos)#" to="1" step="-1">
				<cfset token = mid(body, tokens.pos[x], tokens.len[x])>
				<!--- token is {...} --->
				<cfset cfcName = reReplace(token,"[{}]", "", "all")>
				<cflog file="wiki" text="cfcname=#cfcname#">
				<!--- do we have a component for it? --->
				<cfif (structKeyExists(variables.variableMethods, cfcName)) and (structKeyExists(arguments, 'pageBean'))>
					<cfinvoke component="#variables.variableMethods[cfcName].cfc#" method="render" pageBean="#arguments.pageBean#" returnVariable="result">
					<cflog file="wiki" text="result=#result#">
					<cflog file="wiki" text="left=#left(body, tokens.pos[x]-1)#">
					<cflog file="wiki" text="right=#mid(body, tokens.pos[x]+tokens.len[x], len(body))#">
					<cfset body = left(body, tokens.pos[x]-1) & result & mid(body, tokens.pos[x]+tokens.len[x], len(body))>
				</cfif>
			</cfloop>
		</cfif>
				
		<cfreturn body>		

	</cffunction>
	
	<cffunction name="render_links" output="false" returnType="string" priority="0" 
				hint="Links are rendered using [[url]] or [[url|label]] format. URLs can either be external, fully qualified URLs, or internal URLs in the form of FOO.MOO, where MOO Is a child of FOO.">
		<cfargument name="string" type="string" required="true">
		<cfargument name="webpath" type="string" required="true">
		
		<!--- First test, URLS in the form of [[label]] --->
		<cfset var matches = variables.utils.reFindAll("\[\[[^<>]+?\]\]",arguments.string)>
		<cfset var x = "">
		<cfset var match = "">
		<cfset var label = "">
		<cfset var location = "">
		<cfset var newString = "">
		
		<cfif matches.pos[1] gt 0>
			<cfloop index="x" to="1" from="#arrayLen(matches.pos)#" step="-1">
				<cfset match = mid(arguments.string, matches.pos[x], matches.len[x])>
				<!--- remove [[ and ]] --->
				<cfset match = mid(match, 3, len(match)-4)>
				<!--- Two kinds of matches: path or path|label
				Also, path can be a URL or a internal match. --->
				<cfif listLen(match, "|") gte 2>
					<cfset label = listLast(match, "|")>
					<cfset location = listFirst(match, "|")>
				<cfelse>
					<cfset label = match>
					<cfset location = match>
				</cfif>
				
				<!--- external link --->
				<cfif isValid("url", location)>
					<cfset newString = "<a href=""#location#""><img src=""layouts/images/extlink.gif"">&nbsp;#label#</a>">
				<cfelse>
					<cfset newString = "<a href=""index.cfm?do=cWiki.viewWikiPage&webPath=#location#"">#label#</a>">
				</cfif>
				
				<cfif matches.pos[x] gt 1>
					<cfset arguments.string = left(arguments.string, matches.pos[x]-1) & newString & 
						mid(arguments.string, matches.pos[x]+matches.len[x], len(arguments.string))>
				<cfelse>
					<cfset arguments.string = newString & 
						mid(arguments.string, matches.pos[x]+matches.len[x], len(arguments.string))>
				</cfif>
								
			</cfloop>
		</cfif>
	
		<cfreturn arguments.string>
	</cffunction>

	<cffunction name="render_headers" output="false" returnType="string" priority="1" hint="Use [h]...[/h] for headers. Example: [h]Foo[/h]. To create an smaller headers, you can add more Hs, for up to 6. So for a &lt;h3&gt; tag, use [hhh]">
		<cfargument name="string" type="string" required="true">
		<cfargument name="webpath" type="string" required="true">

		<cfset arguments.string =  rereplaceNoCase(arguments.string,"\[h\](.*?)\[/h\]", "<h1>\1</h1>", "all")>
		<cfset arguments.string =  rereplaceNoCase(arguments.string,"\[hh\](.*?)\[/hh\]", "<h2>\1</h2>", "all")>
		<cfset arguments.string =  rereplaceNoCase(arguments.string,"\[hhh\](.*?)\[/hhh\]", "<h3>\1</h3>", "all")>
		<cfset arguments.string =  rereplaceNoCase(arguments.string,"\[hhhh\](.*?)\[/hhhh\]", "<h4>\1</h4>", "all")>
		<cfset arguments.string =  rereplaceNoCase(arguments.string,"\[hhhhh\](.*?)\[/hhhhh\]", "<h5>\1</h5>", "all")>
		<cfset arguments.string =  rereplaceNoCase(arguments.string,"\[hhhhhh\](.*?)\[/hhhhhh\]", "<h6>\1</h6>", "all")>
		
		<cfreturn arguments.string>	
	</cffunction>

	<cffunction name="render_bold" output="false" returnType="string" priority="1" hint="Use [b]...[/b] for bold. Example: [b]Foo[/b].">
		<cfargument name="string" type="string" required="true">
		<cfargument name="webpath" type="string" required="true">

		<cfset arguments.string =  rereplaceNoCase(arguments.string,"\[b\](.*?)\[/b\]", "<b>\1</b>", "all")>
		
		<cfreturn arguments.string>	
	</cffunction>

	<cffunction name="render_italics" output="true" returnType="string" priority="1" hint="Use [i]...[/i] for italics. Example: [i]Foo[/i].">
		<cfargument name="string" type="string" required="true">
		<cfargument name="webpath" type="string" required="true">

		<cfset arguments.string =  rereplaceNoCase(arguments.string,"\[i\](.*?)\[/i\]", "<i>\1</i>", "all")>

		<cfreturn arguments.string>	
	</cffunction>

	<cffunction name="render_code" output="false" returnType="string" priority="0" 
			hint="Use '[code]' for code. Example: [code]&lt;!-- Foo--&gt;[/code]">
		<cfargument name="string" type="string" required="true">
		<cfargument name="webpath" type="string" required="true">
		<cfset var match = 0 />
		<cfset var strMatch = "" />
		
		<cfloop condition="true">
			<!--- find the next code block in the string --->
			<cfset match = reFindNoCase("(?m)(\[code\])(.*?)(\[/code\])", arguments.string, 0, true) />
			
			<!--- if no matches, break --->
			<cfif NOT match.len[1]>
				<cfbreak />
			</cfif>
			
			<cfset strMatch = Trim(Mid(arguments.string, match.pos[3], match.len[3])) />
			<cfset strMatch = replace(strMatch, "<", "&lt;", "all") />
			<cfset strMatch = replace(strMatch, ">", "&gt;", "all") />
			<cfset strMatch = replace(strMatch, chr(13), "<br>", "all") />
			
			<cfset arguments.string = Mid(arguments.string, 1, match.pos[1] - 1) & "<div class=""code"">" & strMatch & "</div>" & Mid(arguments.string, match.pos[4] + match.len[4], Len(arguments.string) - match.pos[4] + match.len[4]) />
			
		</cfloop>
		
		<cfreturn arguments.string>
	</cffunction>
	
	<cffunction name="render_bullets" output="false" returnType="string" priority="3" hint="Bulleted lists can be created using an asterisk: *">
		<cfargument name="string" type="string" required="true">
		<cfargument name="webpath" type="string" required="true">

		<!--- This should REALLY be a regex. But I couldn't figure it out. --->
		<cfset var newStr = "">
		<cfset var inList = false>
		<cfset var line = "">
		
		<cfloop index="line" list="#trim(arguments.string)#" delimiters="#chr(10)#">
			<cfif left(line,1) is "*">
				<cfif not inList>
					<cfset newStr = newStr & "<ul>#chr(10)#">
					<cfset inList = true>
				</cfif>
				<cfset line = right(line,len(line)-1)>
				<cfset newStr = newStr & "<li>" & line & "</li>">
			<cfelse>
				<cfif inList>
					<cfset newStr = newStr & "</ul>" & chr(10)>
					<cfset inList = false>
				</cfif>
				<cfset newStr = newStr & line>
			</cfif>
			<cfset newStr = newStr & chr(10)>
		</cfloop>
		<cfif inList>
			<cfset newStr = newStr & "</ul>" & chr(10)>
		</cfif>

		<cfreturn newStr>	
	</cffunction>

	<cffunction name="render_orderedlists" output="false" returnType="string" priority="3" hint="Ordered lists can be created using a hash mark: ##">
		<cfargument name="string" type="string" required="true">
		<cfargument name="webpath" type="string" required="true">

		<cfset var newStr = "">
		<cfset var inList = false>
		<cfset var line = "">
		
		<cfloop index="line" list="#trim(arguments.string)#" delimiters="#chr(10)#">
			<cfif left(line,1) is "##">
				<cfif not inList>
					<cfset newStr = newStr & "<ol>#chr(10)#">
					<cfset inList = true>
				</cfif>
				<cfset line = right(line,len(line)-1)>
				<cfset newStr = newStr & "<li>" & line & "</li>">
			<cfelse>
				<cfif inList>
					<cfset newStr = newStr & "</ol>" & chr(10)>
					<cfset inList = false>
				</cfif>
				<cfset newStr = newStr & line>
			</cfif>
			<cfset newStr = newStr & chr(10)>
		</cfloop>
		<cfif inList>
			<cfset newStr = newStr & "</ol>" & chr(10)>
		</cfif>
		
		<cfreturn newStr>	
	</cffunction>
	
	<cffunction name="render_paragraphs" output="false" returnType="string" priority="99" hint="Any double line break will be rendered as a new paragraph.">
		<cfargument name="string" type="string" required="true">
		<cfargument name="webpath" type="string" required="true">
	
		<cfscript>
		/**
		 * Returns a XHTML compliant string wrapped with properly formatted paragraph tags.
		 * 
		 * @param string 	 String you want XHTML formatted. 
		 * @param attributeString 	 Optional attributes to assign to all opening paragraph tags (i.e. style=""font-family: tahoma""). 
		 * @return Returns a string. 
		 * @author Jeff Howden (jeff@members.evolt.org) 
		 * @version 1.1, January 10, 2002 
		 */
		 
		var attributeString = '';
		var returnValue = '';
		if(ArrayLen(arguments) GTE 3) attributeString = ' ' & arguments[3];
		if(Len(Trim(string)))
		    returnValue = '<p' & attributeString & '>' & Replace(string, Chr(13) & Chr(10), '</p>' & Chr(13) & Chr(10) & '<p' & attributeString & '>', 'ALL') & '</p>';
		return returnValue;
		</cfscript>

		<!---
		<cfscript>
		/**
		 * An &quot;enhanced&quot; version of ParagraphFormat.
		 * Added replacement of tab with nonbreaking space char, idea by Mark R Andrachek.
		 * Rewrite and multiOS support by Nathan Dintenfas.
		 * 
		 * @param string 	 The string to format. (Required)
		 * @return Returns a string. 
		 * @author Ben Forta (ben@forta.com) 
		 * @version 3, June 26, 2002 
		 */
		
		//first make Windows style into Unix style
		var str = replace(arguments.string,chr(13)&chr(10),chr(10),"ALL");
		//now make Macintosh style into Unix style
		str = replace(str,chr(13),chr(10),"ALL");
		//now fix tabs
		str = replace(str,chr(9),"&nbsp;&nbsp;&nbsp;","ALL");
		//now return the text formatted in HTML
		//return replace(str,chr(10),"<br />","ALL");
		</cfscript>
		--->
	</cffunction>

	<cffunction name="render_wikiterms" output="true" returnType="string" priority="1" hint="WikiTerms are shortcuts for links to internal pages. Any word which begins with one capital letter - is followed by one or more lower case letters - followed by one more capital - and then one or more letters of any case - will be considered a WikiTerm.">
		<cfargument name="string" type="string" required="true">
		<cfargument name="webpath" type="string" required="true">
		<cfset var urlRegex = "<a href=.*?>.*?</a>">
		<cfset var codeRegex = "<div class=""code"">.*?</div>">
		<!--- regex by Sean Corfield --->		
		<cfset var regex = "\b([A-Z][a-z]+[A-Z][A-Za-z]+)\b">
		<cfset var matches = variables.utils.reFindAll(regex,arguments.string)>
		<cfset var urlMatches = variables.utils.reFindAll(urlRegex,arguments.string)>
		<cfset var codeMatches = variables.utils.reFindAll(codeRegex,arguments.string)>
		<cfset var i = "">
		<cfset var match = "">
		<cfset var matchPos = "">
		<cfset var x = "">
		<cfset var badMatch = "">
		<cfset var newString = "">
		<!--- 
			Logic is:
			Loop through our WT matches. Check to see it is not inside a link match.
		 --->
		<cfif matches.pos[1] gt 0>
			<cfloop index="i" from="#arrayLen(matches.pos)#" to="1" step="-1">
				<cfset match = mid(arguments.string, matches.pos[i], matches.len[i])>
				<!---<cflog file="canvas" text="#match#">--->
				<cfset matchPos = matches.pos[i]>
				<!--- so we got our match pos, loop through URL matches --->
				<cfset badMatch = false>
				<cfloop index="x" from="1" to="#arrayLen(urlMatches.pos)#">
					<cfif urlMatches.pos[x] lt matchPos and (urlMatches.pos[x]+urlMatches.len[x] gt matchPos)>
						<cfset badMatch = true>
						<cfbreak>
					</cfif>
				</cfloop>
				<cfif not badMatch>
					<cfloop index="x" from="1" to="#arrayLen(codeMatches.pos)#">
						<cfif codeMatches.pos[x] lt matchPos and (codeMatches.pos[x]+codeMatches.len[x] gt matchPos)>
							<cfset badMatch = true>
							<cfbreak>
						</cfif>
					</cfloop>
				</cfif>

				<cfif not badMatch>
				
					<cfset newString = "<a href=""index.cfm?do=cWiki.viewWikiPage&webPath=#match#"">#match#</a>">

					<cfif matches.pos[i] gt 1>
						<cfset arguments.string = left(arguments.string, matches.pos[i] - 1) & newString & 
							mid(arguments.string, matches.pos[i]+matches.len[i], len(arguments.string))>
					<cfelse>
						<cfset arguments.string = newString & 
							mid(arguments.string, matches.pos[i]+matches.len[i], len(arguments.string))>
					</cfif>
	
				</cfif>
			</cfloop>
		</cfif>		
		<cfreturn arguments.string>
		
		<!---		
		Removed since it conflicted with url matches
		<cfreturn reReplace(arguments.string, regex, "<a href=""#arguments.webpath#/index.cfm/\1"">\1</a>","all")>
		--->
	</cffunction>
	
	<cffunction name="render_traclinks" access="public" returnType="string" output="true" priority="10" hint="To  link to a specific ticket, you can enter the ticket number preceded
				by a ##(pound sign), ie. ##1 and Skweegee will automatically link to that ticket.">	
		<cfargument name="string" type="string" required="true">
		<cfargument name="webpath" type="string" required="false">
		
		<cfset var regex = "##\d+">
		<cfset var matches = variables.utils.reFindAll(regex,arguments.string)>
		<!--- <cfset var matches = reFind("##\d+", arguments.string, 1,true)> --->
		<cfset var match = "">
		<cfset var urlString = "<a href='index.cfm?event=Ticket.editTicket&ticketID=">
		<cfset var endUrlString = "</a>">
		<cfset var newString = "">
		
		<cfif matches.pos[1] gt 0>
			<cfloop index="x" to="1" from="#arrayLen(matches.pos)#" step="-1">
				<cfset match = mid(arguments.string, matches.pos[x], matches.len[x])>
				
				<cfset newString = urlString & right(match,len(match)-1) & "'>" & match &endUrlString>
				
				<cfif matches.pos[x] gt 1>
					<cfset arguments.string = left(arguments.string, matches.pos[x]-1) & newString & 
						mid(arguments.string, matches.pos[x]+matches.len[x], len(arguments.string))>
				</cfif>
			</cfloop>
		</cfif>	
	
		<cfreturn arguments.string>
	</cffunction>
	
</cfcomponent>