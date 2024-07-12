curl http://localhost:3000/inject-data/add \
  -H "Content-Type: application/json" \
  --data-binary @output_article.json \
  -X POST

