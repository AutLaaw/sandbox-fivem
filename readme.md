![Logo](https://i.ibb.co/Tm01NWq/banner.png)

# Sandbox RP

This is a heavily modified version of the Mythic Framework for Sandbox RP. It use to use a custom component-based system, but now it uses a custom export-based system, with all UIs built in React. This codebase is released with full permissions from the original Mythic Framework authors, Alzar & Dr. Nick.

---

## Dependencies

Ensure the following packages are installed:

| Package          | Download Link                                                                 |
| ---------------- | ---------------------------------------------------------------------------- |
| Node.js          | [Download Here](https://nodejs.org/en/download)                              |
| MariaDB          | [Download Here](https://mariadb.org/download/?t=mariadb&p=mariadb&r=12.0.2) (v12.0.2) |
| HeidiSQL         | [Download Here](https://www.heidisql.com/download.php) (*can be installed via MariaDB) |
| Git for Windows  | [Download Here](https://git-scm.com/download/win)                            |
| Bun              | [Download Here](https://bun.sh)                                              |

---

## Prerequisites & Setup

1. **Download the Source Code**  
   Clone or download the repository from GitHub.

2. **Extract Files**  
   Extract the `sandbox-fivem` folder and open it.

3. **Download FiveM Artifact**  
   Download the latest FiveM Windows Artifact: [Download Here](https://artifacts.jgscripts.com).

4. **Set Up Artifact Folder**  
   - Create a new `artifact` folder in the root directory.
   - Move the downloaded artifact files into the `artifact` folder.

5. **Configure Databases**  
   - Update `database.ptr.cfg` with the correct **Heidi/MariaDB** information.

6. **Add CFX Key**  
   Add your `cfx` key to the `sv_licenseKey` field in the configuration. (*A default key will be added soon for MLO support.)

---

## Importing Database (MariaDB)

1. Open **HeidiSQL**.
2. Import the `database.sql` file.

---

## Launching the Server

1. **First-Time Setup**  
   - Launch the server using `./artifact/FXServer.exe`.
   - Follow the prompts to create a **txAdmin** username/password and link your FiveM account.

2. **Project Setup**  
   - Link the project to an existing project.
   - Set the file paths for the `.cfg` files.

3. **Enable OneSync**  
   - In **txAdmin**, enable `OneSync` for proper server functionality.
   - Restart the server.

![txAdmin](https://i.ibb.co/0yfp7Qt/txadmin.jpg)

---

## Admin Permissions

1. **Assign Roles**  
   Edit the `./config/permissions.cfg` file to assign roles such as `management`, `dev`, `admin`, or `operations`.

2. **Grant Global Admin**  
   To grant `management` permissions to all players, set `danger_everyone_is_admin` to `1` in `./config/core.ptr.cfg`.  
   **Warning:** This is highly discouraged for production environments as it poses significant security risks.

3. **Access Admin Tools**  
   Use `/admin` or `/staff` to access the admin tool.

---

## Logging

- **Discord Logging**  
  Logging works only in `production` mode. To enable logs on a development server, set the environment to `prod` in `core.ptr.cfg`.
