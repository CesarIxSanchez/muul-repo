import http from 'node:http';

const port = Number(process.env.PORT ?? 8080);

const server = http.createServer((request, response) => {
  if (request.url === '/health') {
    response.writeHead(200, { 'content-type': 'application/json' });
    response.end(JSON.stringify({ status: 'ok', service: 'muul-backend' }));
    return;
  }

  response.writeHead(200, { 'content-type': 'application/json' });
  response.end(
    JSON.stringify({
      message: 'Muul backend bootstrap running',
      next: [
        'Implement auth endpoints',
        'Implement places/business endpoints',
        'Implement routes and achievements endpoints'
      ]
    })
  );
});

server.listen(port, () => {
  console.log(`muul-backend listening on ${port}`);
});
