FROM mcr.microsoft.com/devcontainers/base:ubuntu-24.04

# Install Lua and build tools
RUN apt-get update && \
    apt-get install -y lua5.4 lua5.4-dev build-essential curl && \
    rm -rf /var/lib/apt/lists/*

# Install LuaRocks
RUN curl -L https://luarocks.org/releases/luarocks-3.11.0.tar.gz | tar xz && \
    cd luarocks-3.11.0 && \
    ./configure --lua-version=5.4 --versioned-rocks-dir && \
    make && make install && \
    cd .. && rm -rf luarocks-3.11.0

# Create a local LuaRocks tree for user vscode
USER vscode
RUN mkdir -p /home/vscode/.luarocks \
    && luarocks config local_by_default true \
    && echo 'export LUA_PATH="/home/vscode/.luarocks/share/lua/5.4/?.lua;/home/vscode/.luarocks/share/lua/5.4/?/init.lua;;"' >> /home/vscode/.bashrc \
    && echo 'export LUA_CPATH="/home/vscode/.luarocks/lib/lua/5.4/?.so;;"' >> /home/vscode/.bashrc \
    && echo 'export PATH="/home/vscode/.luarocks/bin:$PATH"' >> /home/vscode/.bashrc

# Set environment variables for all shells
ENV LUA_PATH="/home/vscode/.luarocks/share/lua/5.4/?.lua;/home/vscode/.luarocks/share/lua/5.4/?/init.lua;;"
ENV LUA_CPATH="/home/vscode/.luarocks/lib/lua/5.4/?.so;;"
ENV PATH="/home/vscode/.luarocks/bin:$PATH"
