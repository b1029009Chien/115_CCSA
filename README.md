# this is NYCU AI CCSA

Here is just make a record

### Homework 2: Create a Client-Server Application using VirtualBox and Vagrant

Objective

Learn how to use Vagrant with VirtualBox to automatically provision two virtual machines:

A server VM that runs a simple web server.
A client VM that can query the server.
The entire environment should be created and configured with a single command: vagrant up

Versions to Use

VirtualBox 7.1.4 (or latest 7.1.x release)
Vagrant 2.4.1 (or latest 2.4.x release)
Requirements

1. Vagrantfile:

Define two Ubuntu 22.04 VMs:

- Server VM (server.local, IP: 192.168.56.10)

   * Provisioned with a script to install Python and run:

      python3 -m http.server 8000 --directory /vagrant &

- Client VM (client.local, IP: 192.168.56.11)

   * Provisioned with curl.

2. Automation

Both machines must be fully ready after vagrant up.

The client should be able to query the server with: curl http://192.168.56.10:8000

3. Using Vagrant

- Demonstrate how to enter the client VM: vagrant ssh client

- Run the test command inside the client VM to verify the server’s response.

4. Deliverables

Submit a single compressed folder containing:

- Your Vagrantfile (with inline or external provisioning scripts).

- A short README.md describing:

   * How to bring up the environment.

   * How to log into the client and test the connection.

   * Screenshots/logs showing a successful client request to the server.


### Homework 3: Create a 3-Tier Web Application with Docker Compose
- Objective
    * You are tasked with building a 3-tier web application using Docker Compose. 
The application will allow users to perform the following actions via a web 
interface:
        * Enter a name into a database.
        * List all entered names.
        * Remove names from the database.
    * Versions to Use
        * VirtualBox 7.1.4 (or latest 7.1.x release)
        * Vagrant 2.4.1 (or latest 2.4.x release)
    * The application will consist of three Docker containers:
        * Database: A PostgreSQL container to store names.
        * Backend: A Flask application (with Gunicorn) that exposes REST API endpoints to interact with the PostgreSQL database.
        *  Frontend: An Nginx web server that serves a simple HTML/JavaScript page for user interaction, and proxies API requests to the backend.
    * The goal is to understand containerization of a multi-tier architecture, use Docker Compose to manage inter-service communication, and ensure the web app functions as expected
- Requirement
    *  Database (PostgreSQL)
        * Run PostgreSQL in its own container.
        * Use a Docker volume to persist data across restarts.
        * Initialize the database with a table names (id SERIAL PRIMARY KEY, name TEXT, created_at TIMESTAMP DEFAULT NOW()).
    * Backend API (Flask + Gunicorn)
        *  Expose the following endpoints under /api:
            * POST /api/names — Adds a new name to the database.
            * GET /api/names — Retrieves all stored names.
            * DELETE /api/names/{id} — Removes a name by ID.
        * Implement basic validation (e.g., names cannot be empty, max length 50).
        * Run Flask using Gunicorn inside the container, bound to 0.0.0.0:8000.
    * Frontend (Nginx)
        *  Serve a static HTML/JavaScript page that allows users to:
            * Submit a name to the database.
            * View the list of entered names.
            * Remove a name from the list.
            * Configure Nginx to:
                * Serve static files at /.
                * Proxy /api/ requests to the backend container
    * Docker Compose
        * Define a docker-compose.yml with three services: db, backend, frontend.
        * Use Docker Compose networks so the backend can reach the database and Nginx can reach the backend.
        * Expose only the Nginx container to the host (e.g., port 8080:80)