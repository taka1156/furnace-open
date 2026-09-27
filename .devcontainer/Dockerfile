FROM ubuntu:24.04

ARG TERRAFORM_VERSION=1.13.3
ARG CF_TERRAFORMING_VERSION=0.29.0

ENV LANG=ja_JP.UTF-8 \
    LANGUAGE=ja_JP:ja \
    LC_ALL=ja_JP.UTF-8 \
    TZ=Asia/Tokyo

RUN <<-EOF
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y \
    bash \
    ca-certificates \
    curl \
    git \
    jq \
    unzip \
    make \
    openssh-client \
    locales \
    tzdata \
    bash-completion
rm -rf /var/lib/apt/lists/*
EOF

RUN <<-EOF
locale-gen ja_JP.UTF-8

# --- secretlint ---
curl -fsSL  "https://github.com/secretlint/secretlint/releases/download/v13.0.6/secretlint-13.0.6-linux-arm64" -o /usr/bin/secretlint
chmod +x /usr/bin/secretlint

# --- Terraform ---
# hc-installのGPG署名検証(HashiCorpの旧鍵失効問題)を回避するため
# バイナリを直接取得し、SHA256SUMSでの整合性検証のみ行う
curl -fsSL "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip" \
    -o /tmp/terraform.zip
curl -fsSL "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_SHA256SUMS" \
    -o /tmp/terraform_SHA256SUMS
grep "terraform_${TERRAFORM_VERSION}_linux_amd64.zip" /tmp/terraform_SHA256SUMS \
    | (cd /tmp && sha256sum -c -)
unzip /tmp/terraform.zip -d /usr/local/bin
rm /tmp/terraform.zip /tmp/terraform_SHA256SUMS

# --- cf-terraforming ---
curl -fsSL "https://github.com/cloudflare/cf-terraforming/releases/download/v${CF_TERRAFORMING_VERSION}/cf-terraforming_${CF_TERRAFORMING_VERSION}_linux_amd64.tar.gz" \
    -o /tmp/cf-terraforming.tar.gz
tar -xzf /tmp/cf-terraforming.tar.gz -C /usr/local/bin
rm /tmp/cf-terraforming.tar.gz

terraform version
cf-terraforming --version
EOF

RUN <<-EOF
curl -fsSL https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh -o ~/.git-prompt.sh
curl -fsSL https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash -o ~/.git-completion.sh

echo '[ -f ~/.git-prompt.sh ] && source ~/.git-prompt.sh' >> ~/.bashrc
echo '[ -f ~/.git-completion.sh ] && source ~/.git-completion.sh' >> ~/.bashrc
echo '[ -f /usr/share/bash-completion/bash_completion ] && source /usr/share/bash-completion/bash_completion' >> ~/.bashrc
echo 'GIT_PS1_SHOWDIRTYSTATE=true' >> ~/.bashrc
echo 'GIT_PS1_SHOWUNTRACKEDFILES=true' >> ~/.bashrc
echo 'GIT_PS1_SHOWUPSTREAM=auto' >> ~/.bashrc
git config --system --add safe.directory /workspace
echo 'export PS1="\[\033[01;32m\]\u@\h\[\033[01;33m\] \w \[\033[01;31m\]\$(__git_ps1 \"(%s)\") \\n\[\033[01;34m\]\\$ \[\033[00m\]"' >> ~/.bashrc
EOF

WORKDIR /workspace

CMD ["bash"]
