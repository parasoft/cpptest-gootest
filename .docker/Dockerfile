FROM cpptest-ct-std:latest

USER parasoft:parasoft

# install GitHub Runner
RUN mkdir actions-runner && cd actions-runner && \
    curl -o actions-runner-linux-x64-2.315.0.tar.gz -L https://github.com/actions/runner/releases/download/v2.315.0/actions-runner-linux-x64-2.315.0.tar.gz && \
    tar xzf ./actions-runner-linux-x64-2.315.0.tar.gz

# > docker build -t cpptest-ct-std:runner .
