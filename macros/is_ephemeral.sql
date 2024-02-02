{%- macro is_ephemeral() -%}

    {% if target.type == 'spark' %}
        {{ return('ephemeral') }}  
    {% else %} 
       {{ return('view') }}  
    {% endif %}

{%- endmacro -%}
