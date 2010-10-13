// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

function load_clients_schema_example()
{
    var sample_schema = $('clients_schema_example').innerText;
    var textarea = $('schema');
    textarea.innerText = sample_schema;
}

function load_user_levels_schema_example()
{
    var sample_schema = $('user_levels_schema_example').innerText;
    var textarea = $('user_levels');
    textarea.innerText = sample_schema;
}

function load_user_name_query_examples()
{
    var sample_user_name = $('user_name_example').innerText;
    var input = $('user_name');
    input.value = sample_user_name;
    var sample_query = $('query_example').innerText;
    var textarea = $('query');
    textarea.innerText = sample_query;
}