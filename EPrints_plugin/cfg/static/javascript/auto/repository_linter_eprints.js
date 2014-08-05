
//This is the Eprints plugin to provide a workflow interface to the repository linter api (Paul Mucur and Richard Wincewicz)
// https://github.com/rwincewicz/RepositoryLinter

//Rory McNicholl, University of London Computer Centre

//requires jQuery + jQuery.ui.dialog

// and something to press in workflow file eg:
// <component type="XHTML"><button id="linter_button">SOS</button></component>

(function($) {

//store eprint record JSON object in this
var eprint_json;
//init dialog element
var dialog = $( '<div></div>' );

$(document).ready(function(){


	//Get eprintid from hidden input field in workflow
	var eprintid =  $("#eprintid").val();
	//URL for JSON object of Eprint record (randomised end so not cached)
	var json_url = "/cgi/export/eprint/"+eprintid+"/JSON/"+Math.random();

	//click linter button which will reside somwhere in workflow form (/workflow/eprint/default.xml)
	$("#linter_button").on("click",function(){
		//If already have eprint JSON skip straight to linter call
		if(eprint_json != undefined){
			linter_api_call();
       			return false;
		} 
		$.ajax({
	  		url: json_url,
        		dataType: "json", 
                    	success: function(data, status, XHR) {
				//set json to (whatever!) the export call returns
				eprint_json = data;
				linter_api_call();
                    	},
                    	complete: function(XHR, status) {
				//uncomment for unconditioanl report on request response
				//if(console != undefined)console.log(status);                  
			},
                    	fail: function(XHR, status, e){
                    		alert("FAIL:"+status+" "+e);
                    	},                      
            	}); //ajax (url)
         return false; 
        }); //on click
});

function linter_api_call(){

	//proxy (not satisfactorily written) if cross-domain requests are a problem
	//var url = "/cgi/linter_proxy";
	
	//var url = "http://www-staging.altmetric.com:4567/validate"; (gone)

	//change local host to reflect location of linter api
	var url = "localhost:4567/validate";

	//Post eprint JSON to linter api
	$.ajax({
  		url: url,
		type: "post",
		dataType: 'json',
		data: JSON.stringify(eprint_json),
                success: function(data, status, XHR) {
			//clear dialog
			$(dialog).html("");
			//list the errors first
			var errors = $( '<ul></ul>' );
			$.each(data.errors, function(key,value){
				errors.append('<li>'+value+'</li>');
			});
			$(dialog).append(errors);

			//DOI suggestions
			if(data.errors.indexOf('DOI field is missing') != -1 && data.hasOwnProperty('dois')){
			
				var doi = $('<ul class="id_number"><p style="font-weight: bold;">Suggested DOIs (titles displayed)</p></ul>');	

				$.each(data.dois, function(key,value){
					var li = $('<li><a title="'+value.doi+'" style="cursor: pointer;">'+value.title+'</a></li>');
					$(li).on('click', 'a', function(){
						$("input[id*='id_number']:first").val($(this).attr('title'));	
						eprint_json.id_number = $(this).attr('title');
						$(this).css({color: '#0a0', 'font-weight': 'bold'});
						//auto re-call the linter api as DOi should unlock more juicy metadata
						linter_api_call();	
					});
					$(doi).append(li);
				});
				$(dialog).append(doi);
			}
			//Publisher suggestions
			if(data.errors.indexOf('Publisher field is missing') != -1 && data.hasOwnProperty('publishers')){		
				var pubs = $('<ul class="publisher"><p style="font-weight: bold;">Suggested Publishers</p></ul>');	
				$.each(data.publishers, function(key,value){
					var li = $('<li><a style="cursor: pointer;">'+value.name+'</a></li>');
					$(li).on('click','a', function(){
						$("input[id*='publisher']:first").val($(this).text());	
						eprint_json.publisher = $(this).text();
						$(this).css({color: '#0a0', 'font-weight': 'bold'});
					});
					$(pubs).append(li);
				});
				$(dialog).append(pubs);
			}
			//Publication (jounral) AND ISSN suggestions (these should come from linter as a pair)
			if((data.errors.indexOf('ISSN field is missing') != -1 || data.errors.indexOf('Publication field is missing') != -1) && data.hasOwnProperty('publications') && data.publications.length > 0){
			
				var issn = $('<ul class="issn"><p style="font-weight: bold;">Suggested Publications (Journal titles displayed)</p></ul>');	
				$.each(data.publications, function(key,value){
					var li = $('<li><a title="'+value.issn+'">'+value.title+'</a></li>');
					$(li).on('click', 'a', function(){
						$("input[id*='issn']:first").val($(this).attr('title'));
						$("input[id*='publication']:first").val($(this).text());
						eprint_json.issn = $(this).attr('title');
						eprint_json.publication = $(this).text();
						$(this).css({color: '#0a0', 'font-weight': 'bold'});
					});
					$(issn).append(li);
				});
				$(dialog).append(issn);
			}
			//Funders suggestions	
			if(data.errors.indexOf('Funders field is missing') != -1 && data.hasOwnProperty('funders') && data.funders.length > 0){
			
				var funders = $('<ul class="funders"><p style="font-weight: bold;">Suggested funders</p></ul>');	
				$.each(data.funders, function(key,value){
					var li = $('<li><a title="'+value.name+'">'+value.name+'</a></li>');
					$(li).on('click', 'a', function(){
						//funders is a multiple field so fill in the first empty slot (Thanks to PM)
						$("input[id*=funders]").filter(function (i, e) { return $(e).val() === ''; }).eq(0).val($(this).attr('title'));
						$(this).css({color: '#0a0', 'font-weight': 'bold'});
					});
					$(funders).append(li);
				});
				$(dialog).append(funders);
			}
			//Creators suggestions
			if(data.errors.indexOf('Creators field is missing') != -1 && data.hasOwnProperty('authors') && data.authors.length > 0){	
				var creators = $('<ul class="creators"><p style="font-weight: bold;">Suggested creators</p></ul>');	
				$.each(data.authors, function(key,value){
					var li = $('<li><a data-given="'+value.given+'" data-family="'+value.family+'">'+value.given+' '+value.family+'</a></li>');
					$(li).on('click', 'a', function(){
						//creators is a multiple comound field so fill in the first empty slots (Double thanks to PM)

						$("input[id*=creator][id*='name_given']").filter(function (i, e) { return $(e).val() === ''; }).eq(0).val($(this).attr('data-given'));	
						$("input[id*=creator][id*='name_family']").filter(function (i, e) { return $(e).val() === ''; }).eq(0).val($(this).attr('data-family'));	
						$(this).css({color: '#0a0', 'font-weight': 'bold'});
					});
					$(creators).append(li);
				});
				$(dialog).append(creators);
			}
			//Project suggestions (NB Search based on creators names)
			if(data.hasOwnProperty('funding') && data.funding.length > 0){
				var projects = $('<ul class="creators"><p style="font-weight: bold;">Suggested projects (based on Creators)</p></ul>');	
				$.each(data.funding, function(key,value){
					$.each(value.projects, function(key,val){	
						var li = $('<li><a title="'+val.title+'">'+val.title+'</a></li>');
						$(li).on('click', 'a', function(){
							$("input[id*=projects]").filter(function (i, e) { return $(e).val() === ''; }).eq(0).val($(this).attr('title'));
							$(this).css({color: '#0a0', 'font-weight': 'bold'});
						});
						$(projects).append(li);

					});
				});	
				$(dialog).append(projects);
			}
			$(dialog).dialog({width: 600, autoOpen: false, resizable: false});
			$(dialog).parent().css({position: 'fixed'}).end().dialog('open');

		}, 
		complete: function(XHR, status) {
			//if(console != undefined)console.log(status);                  
		},
                fail: function(XHR, status, e){
                    	alert("FAIL:"+status+" "+e);
                },                      
	}); //ajax (url)
}       
 
})(jQuery);




