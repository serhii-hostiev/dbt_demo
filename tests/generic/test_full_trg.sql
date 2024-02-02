
{% test test_full_trg(model, model_src) %}

    SELECT s.*
    FROM {{ model_src }} AS s
    LEFT JOIN {{ model }} AS t ON s.id = t.id
    WHERE t.id IS NULL

{% endtest %}
