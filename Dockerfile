FROM .NET 5

RUN echo "Installing PowerShell" && \
    curl -L https://github.com/PowerShell/PowerShell/releases/download/v7.0.2/powershell-7.0.2-linux-alpine-x64.tar.gz -o /tmp/powershell.tar.gz && \
    mkdir -p /opt/microsoft/powershell/7 && \
    tar zxf /tmp/powershell.tar.gz -C /opt/microsoft/powershell/7  && \
    chmod +x /opt/microsoft/powershell/7/pwsh && \
    echo "skipping symlink" # ln -s /opt/microsoft/powershell/7/pwsh /usr/bin/pwsh

# get .NET core 3.1 for the NuKeeper dependencies
RUN echo "Installing dotnetcore 3.1:" && \
    dotnet_version=3.1.10 && \
    wget -O dotnet.tar.gz https://dotnetcli.azureedge.net/dotnet/Runtime/$dotnet_version/dotnet-runtime-$dotnet_version-linux-musl-x64.tar.gz && \
    dotnet_sha512='ee54d74e2a43f4d8ace9b1c76c215806d7580d52523b80cf4373c132e2a3e746b6561756211177bc1bdbc92344ee30e928ac5827d82bf27384972e96c72069f8' && \
    echo "$dotnet_sha512  dotnet.tar.gz" | sha512sum -c - && \
    mkdir -p /usr/share/dotnet && \
    tar -C /usr/share/dotnet -oxzf dotnet.tar.gz && \
    # skip adding the symlink since that already is available with .NET 5.0 in it
    #- ln -s /usr/share/dotnet/dotnet /usr/bin/dotnet && \
    rm dotnet.tar.gz
    
COPY nukeeper.ps1 /