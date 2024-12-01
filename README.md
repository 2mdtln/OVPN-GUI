# OpenVPN GUI Client

A simple and user-friendly GUI for managing OpenVPN connections.

![gif](assets/dem.gif)

This project was developed in a short amount of time, so it’s not perfect. I welcome all [contributions](#-Contributing) to help improve it!

---

## 🚀 Features

- **Easy Connection Management**: Connect, disconnect, and switch profiles with just a few clicks.
- **Profile Handling**: Load your `.ovpn` files seamlessly.
- **Minimal Design**: A clean, simple interface to get things done quickly.
- **Linux-First**: Currently, this tool is developed and tested only for Linux systems.  

> **Note**: While the project is focused on Linux, it can be built for Windows and macOS with some modifications. Contributions to expand compatibility are welcome!

---

## 🌟 Why This Project?

I built this tool as a fun personal project to streamline my workflow while solving CTF challenges. While it's not intended for professional use, I hope it might also be helpful to others.


Feel free to star ⭐ the repo if you find it useful!

---


## 🛠️ Installation

To install the OpenVPN GUI Client on your Linux system, follow these steps:


1. ⚙️ Install required dependencies 

Before installing the application, ensure the following dependencies are installed:
`libgtk-3-dev`, `openvpn`

Run the following command to install them:

`sudo apt-get update`

`sudo apt-get install -y libgtk-3-dev openvpn`


2. Download the .deb package

Download the latest version of the `.deb` package from [releases](https://github.com/2mdtln/OVPN-GUI/releases). The file name will be `ovpngui-1.0.0+1.0.0-linux.deb`.

3. Install the package

Open a terminal and run the following command to install the .deb package:

`sudo dpkg -i ovpngui-1.0.0+1.0.0-linux.deb`

This will install the OpenVPN GUI Client on your system.
If you encounter any dependency issues, run the following command to resolve them:

`sudo apt install -f`

4. Launch the application

After installation, you can launch the GUI with the following command:

`sudo ovpngui`

---

### 🤝 Contributing

Contributions are welcome!
Whether it's fixing bugs, suggesting features, or improving the documentation, I'd love your input. This is my first open-source project, and I'm excited to collaborate and learn with the community.

How to Contribute

1. Fork the repository.

2. Create your feature branch:

`git checkout -b feature/NewFeature`

4. Commit your changes:

`git commit -m 'Add some NewFeature'`

5. Push to the branch:

`git push origin feature/NewFeature`

6. Open a pull request.

---

### 📜 License
This project is licensed under the [GPL-3.0 License](LICENSE).
