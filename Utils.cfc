<cfcomponent>
<!---
 Returns all the matches of a regular expression within a string.
 
 @param regex 	 Regular expression. (Required)
 @param text 	 String to search. (Required)
 @return Returns a structure. 
 @author Ben Forta (ben@forta.com) 
 @version 1, July 15, 2005 
--->
<cffunction name="reFindAll" output="false" returnType="struct">
   <cfargument name="regex" type="string" required="true">
   <cfargument name="text" type="string" required="true">

   <!--- Define local variables --->	
   <cfset var results=structNew()>
   <cfset var pos=1>
   <cfset var subex="">
   <cfset var done=false>
	
   <!--- Initialize results structure --->
   <cfset results.len=arraynew(1)>
   <cfset results.pos=arraynew(1)>

   <!--- Loop through text --->
   <cfloop condition="not done">

      <!--- Perform search --->
      <cfset subex=reFind(arguments.regex, arguments.text, pos, true)>
      <!--- Anything matched? --->
      <cfif subex.len[1] is 0>
         <!--- Nothing found, outta here --->
         <cfset done=true>
      <cfelse>
         <!--- Got one, add to arrays --->
         <cfset arrayappend(results.len, subex.len[1])>
         <cfset arrayappend(results.pos, subex.pos[1])>
         <!--- Reposition start point --->
         <cfset pos=subex.pos[1]+subex.len[1]>
      </cfif>
   </cfloop>

   <!--- If no matches, add 0 to both arrays --->
   <cfif arraylen(results.len) is 0>
      <cfset arrayappend(results.len, 0)>
      <cfset arrayappend(results.pos, 0)>
   </cfif>

   <!--- and return results --->
   <cfreturn results>
</cffunction>

<cffunction name="notifyAdmin" access="public" output="true" returntype="void">
	<cfargument name="to" default="#application.adminemail#" required="false">
	<cfargument name="from" default="#application.adminemail#" required="false">
	<cfargument name="subject" default="Skweegee Notification" required="false">
<cfmail to="#arguments.to#" from="#arguments.from#" subject="#arguments.subject#" type="text">
A New User Has Registered on Skweegee!

</cfmail>
</cffunction>

<!--- 
Copyright for coloredCode function. Also note that Jeff Coughlin made some mods to this as well.
=============================================================
	Utility:	ColdFusion ColoredCode v3.2
	Author:		Dain Anderson
	Email:		webmaster@cfcomet.com
	Revised:	June 7, 2001
	Download:	http://www.cfcomet.com/cfcomet/utilities/
============================================================= 
--->
	<cffunction name="coloredCode" output="false" returnType="string" access="public"
			   hint="Colors code">
		<cfargument name="dataString" type="string" required="true">
		<cfargument name="class" type="string" required="true">

		<cfset var data = trim(arguments.dataString) />
		<cfset var eof = 0>
		<cfset var bof = 1>
		<cfset var match = "">
		<cfset var orig = "">
		<cfset var chunk = "">

		<cfscript>
		/* Convert special characters so they do not get interpreted literally; italicize and boldface 
		data = REReplaceNoCase(data, '&([[:alpha:]]{2,});', '«strong»«em»&amp;\1;«/em»«/strong»', 'ALL');*/
	
		/* Convert many standalone (not within quotes) numbers to blue, ie. myValue = 0 */
		data = REReplaceNoCase(data, "(gt|lt|eq|is|,|\(|\))([[:space:]]?[0-9]{1,})", "\1«span style='color: ##0000ff'»\2«/span»", "ALL");
	
		/* Convert normal tags to navy blue */
		data = REReplaceNoCase(data, "<(/?)((!d|b|c(e|i|od|om)|d|e|f(r|o)|h|i|k|l|m|n|o|p|q|r|s|t(e|i|t)|u|v|w|x)[^>]*)>", "«span style='color: ##000080'»<\1\2>«/span»", "ALL");
	
		/* Convert all table-related tags to teal */
		data = REReplaceNoCase(data, "<(/?)(t(a|r|d|b|f|h)([^>]*)|c(ap|ol)([^>]*))>", "«span style='color: ##008080'»<\1\2>«/span»", "ALL");
	
		/* Convert all form-related tags to orange */
		data = REReplaceNoCase(data, "<(/?)((bu|f(i|or)|i(n|s)|l(a|e)|se|op|te)([^>]*))>", "«span style='color: ##ff8000'»<\1\2>«/span»", "ALL");
	
		/* Convert all tags starting with 'a' to green, since the others aren't used much and we get a speed gain */
		data = REReplaceNoCase(data, "<(/?)(a[^>]*)>", "«span style='color: ##008000'»<\1\2>«/span»", "ALL");
	
		/* Convert all image and style tags to purple */
		data = REReplaceNoCase(data, "<(/?)((im[^>]*)|(sty[^>]*))>", "«span style='color: ##800080'»<\1\2>«/span»", "ALL");
	
		/* Convert all ColdFusion, SCRIPT and WDDX tags to maroon */
		data = REReplaceNoCase(data, "<(/?)((cf[^>]*)|(sc[^>]*)|(wddx[^>]*))>", "«span style='color: ##800000'»<\1\2>«/span»", "ALL");
	
		/* Convert all inline "//" comments to gray (revised) */
		data = REReplaceNoCase(data, "([^:/]\/{2,2})([^[:cntrl:]]+)($|[[:cntrl:]])", "«span style='color: ##808080'»«em»\1\2«/em»«/span»", "ALL");
	
		/* Convert all multi-line script comments to gray */
		data = REReplaceNoCase(data, "(\/\*[^\*]*\*\/)", "«span style='color: ##808080'»«em»\1«/em»«/span»", "ALL");
	
		/* Convert all HTML and ColdFusion comments to gray */	
		/* The next 10 lines of code can be replaced with the commented-out line following them, if you do care whether HTML and CFML 
		   comments contain colored markup. */

		while(NOT EOF) {
			Match = REFindNoCase("<!--" & "-?([^-]*)-?-->", data, BOF, True);
			if (Match.pos[1]) {
				Orig = Mid(data, Match.pos[1], Match.len[1]);
				Chunk = REReplaceNoCase(Orig, "«(/?[^»]*)»", "", "ALL");
				BOF = ((Match.pos[1] + Len(Chunk)) + 38); // 38 is the length of the SPAN tags in the next line
				data = Replace(data, Orig, "«span style='color: ##808080'»«em»#Chunk#«/em»«/span»");
			} else EOF = 1;
		}


		/* Convert all quoted values to blue */
		data = REReplaceNoCase(data, """([^""]*)""", "«span style=""color: ##0000ff""»""\1""«/span»", "all");

		/* Convert left containers to their ASCII equivalent */
		data = REReplaceNoCase(data, "<", "&lt;", "ALL");

		/* Convert right containers to their ASCII equivalent */
		data = REReplaceNoCase(data, ">", "&gt;", "ALL");

		/* Revert all pseudo-containers back to their real values to be interpreted literally (revised) */
		data = REReplaceNoCase(data, "«([^»]*)»", "<\1>", "ALL");

		/* ***New Feature*** Convert all FILE and UNC paths to active links (i.e, file:///, \\server\, c:\myfile.cfm) */
		data = REReplaceNoCase(data, "(((file:///)|([a-z]:\\)|(\\\\[[:alpha:]]))+(\.?[[:alnum:]\/=^@*|:~`+$%?_##& -])+)", "<a target=""_blank"" href=""\1"">\1</a>", "ALL");

		/* Convert all URLs to active links (revised) */
		data = REReplaceNoCase(data, "([[:alnum:]]*://[[:alnum:]\@-]*(\.[[:alnum:]][[:alnum:]-]*[[:alnum:]]\.)?[[:alnum:]]{2,}(\.?[[:alnum:]\/=^@*|:~`+$%?_##&-])+)", "<a target=""_blank"" href=""\1"">\1</a>", "ALL");

		/* Convert all email addresses to active mailto's (revised) */
		data = REReplaceNoCase(data, "(([[:alnum:]][[:alnum:]_.-]*)?[[:alnum:]]@[[:alnum:]][[:alnum:].-]*\.[[:alpha:]]{2,})", "<a href=""mailto:\1"">\1</a>", "ALL");
		</cfscript>

		<!--- mod by ray --->
		<!--- change line breaks at end to <br /> 
		<cfset data = replace(data,chr(13),"<br />","all") />--->
		<!--- replace tab with 3 spaces --->
		<cfset data = replace(data,chr(9),"&nbsp;&nbsp;&nbsp;","all") />
		<!--- <cfset data = "<div class=""#arguments.class#"">" & data &  "</div>" /> --->
		
		<cfreturn data>
	</cffunction>

</cfcomponent>