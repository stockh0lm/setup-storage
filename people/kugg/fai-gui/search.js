function hideSoon()
{
	document.getElementById("search").style.borderColor='#cccccc';
	document.getElementById("search").style.backgroundColor='#ffffff';	
	setTimeout ("hideHint()", 500);

}

function hideHint()
{
	document.getElementById("hint").innerHTML='';
}

function highlight(this_element)
{
	document.getElementById(this_element).style.borderColor='#010101';
	document.getElementById(this_element).style.backgroundColor='#f6f0d0';


	if (document.getElementById(this_element).value=="Search...")
	{
	document.getElementById(this_element).value='';
	}
}

function ajaxSearch(question)
{
	var xmlHttp;
	//Initial browser check
	try
	{
		xmlHttp=new XMLHttpRequest();
	}
	catch (e)
	{
		alert("Your browser can not search in this form since it lacks ajax support.");
		return false;
	}

	xmlHttp.onreadystatechange=function()
	{
		if(xmlHttp.readyState==4)
		{
			document.getElementById("hint").innerHTML=xmlHttp.responseText;
		}
	}

	xmlHttp.open("GET","search.result",true);
	xmlHttp.send(question);
	alert(xmlHttp.readyState + document.searchform.g.value);

}
