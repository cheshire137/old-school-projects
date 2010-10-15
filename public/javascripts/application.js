// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

function load_clients_schema_example()
{
    var sample_schema = $('clients_schema_example').innerHTML;
    var textarea = $('schema');
    textarea.innerHTML = sample_schema;
}

function load_user_levels_schema_example()
{
    var sample_schema = $('user_levels_schema_example').innerHTML;
    var textarea = $('user_levels');
    textarea.innerHTML = sample_schema;
}

function load_user_name_query_examples()
{
    var sample_user_name = $('user_name_example').innerHTML;
    var input = $('user_name');
    input.value = sample_user_name;
    var sample_query = $('query_example').innerHTML;
    var textarea = $('query');
    textarea.innerHTML = sample_query;
}