#!/bin/bash

# AFHAM Website - Cloudflare Pages Deployment Script
# This script automates the deployment of the AFHAM website to Cloudflare Pages

set -e  # Exit on any error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_NAME="afham-website"
CLOUDFLARE_ACCOUNT_ID="${CLOUDFLARE_ACCOUNT_ID}"
CLOUDFLARE_API_TOKEN="${CLOUDFLARE_API_TOKEN}"
CUSTOM_DOMAIN="afham.brainsait.io"
BUILD_DIR="dist"
SOURCE_DIR="website"

echo -e "${BLUE}🚀 Starting AFHAM Website Deployment to Cloudflare Pages${NC}"
echo "=========================================================="

# Check required environment variables
check_env_vars() {
    echo -e "${YELLOW}📋 Checking environment variables...${NC}"
    
    if [ -z "$CLOUDFLARE_ACCOUNT_ID" ]; then
        echo -e "${RED}❌ Error: CLOUDFLARE_ACCOUNT_ID environment variable is not set${NC}"
        echo "   Please set it with: export CLOUDFLARE_ACCOUNT_ID=your_account_id"
        exit 1
    fi
    
    if [ -z "$CLOUDFLARE_API_TOKEN" ]; then
        echo -e "${RED}❌ Error: CLOUDFLARE_API_TOKEN environment variable is not set${NC}"
        echo "   Please set it with: export CLOUDFLARE_API_TOKEN=your_api_token"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Environment variables configured${NC}"
}

# Install dependencies
install_dependencies() {
    echo -e "${YELLOW}📦 Installing dependencies...${NC}"
    
    # Check if Node.js is installed
    if ! command -v node &> /dev/null; then
        echo -e "${RED}❌ Node.js is not installed. Please install Node.js 18+ first.${NC}"
        exit 1
    fi
    
    # Check if npm is installed
    if ! command -v npm &> /dev/null; then
        echo -e "${RED}❌ npm is not installed. Please install npm first.${NC}"
        exit 1
    fi
    
    # Install Wrangler CLI if not present
    if ! command -v wrangler &> /dev/null; then
        echo "Installing Wrangler CLI..."
        npm install -g wrangler
    fi
    
    echo -e "${GREEN}✅ Dependencies ready${NC}"
}

# Prepare build directory
prepare_build() {
    echo -e "${YELLOW}🏗️ Preparing build directory...${NC}"
    
    # Clean previous build
    if [ -d "$BUILD_DIR" ]; then
        rm -rf "$BUILD_DIR"
    fi
    
    # Create build directory
    mkdir -p "$BUILD_DIR"
    
    # Copy website files
    cp -r "$SOURCE_DIR"/* "$BUILD_DIR"/
    
    # Optimize images (if imageoptim-cli is available)
    if command -v imageoptim &> /dev/null; then
        echo "Optimizing images..."
        find "$BUILD_DIR" -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" | xargs imageoptim
    fi
    
    # Minify CSS and JS (if uglifycss and uglifyjs are available)
    if command -v uglifycss &> /dev/null; then
        echo "Minifying CSS..."
        find "$BUILD_DIR" -name "*.css" -exec uglifycss {} --output {} \;
    fi
    
    if command -v uglifyjs &> /dev/null; then
        echo "Minifying JavaScript..."
        find "$BUILD_DIR" -name "*.js" -exec uglifyjs {} --compress --mangle --output {} \;
    fi
    
    echo -e "${GREEN}✅ Build directory prepared${NC}"
}

# Authenticate with Cloudflare
authenticate_cloudflare() {
    echo -e "${YELLOW}🔐 Authenticating with Cloudflare...${NC}"
    
    # Set Cloudflare credentials
    wrangler login --api-token "$CLOUDFLARE_API_TOKEN"
    
    echo -e "${GREEN}✅ Cloudflare authentication successful${NC}"
}

# Deploy to Cloudflare Pages
deploy_to_pages() {
    echo -e "${YELLOW}🌐 Deploying to Cloudflare Pages...${NC}"
    
    # Deploy using Wrangler
    wrangler pages deploy "$BUILD_DIR" \
        --project-name "$PROJECT_NAME" \
        --compatibility-date="$(date +'%Y-%m-%d')" \
        --compatibility-flags="streams_enable_constructors"
    
    echo -e "${GREEN}✅ Deployment successful${NC}"
}

# Configure custom domain
configure_domain() {
    echo -e "${YELLOW}🔗 Configuring custom domain...${NC}"
    
    # Add custom domain using Cloudflare API
    curl -X POST "https://api.cloudflare.com/client/v4/accounts/$CLOUDFLARE_ACCOUNT_ID/pages/projects/$PROJECT_NAME/domains" \
        -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
        -H "Content-Type: application/json" \
        --data '{"name":"'$CUSTOM_DOMAIN'"}'
    
    echo -e "${GREEN}✅ Custom domain configured${NC}"
}

# Set up redirects and headers
configure_rules() {
    echo -e "${YELLOW}⚙️ Configuring redirects and headers...${NC}"
    
    # Create _redirects file
    cat > "$BUILD_DIR/_redirects" << 'EOF'
# AFHAM Website Redirects

# Redirect www to non-www
https://www.afham.brainsait.io/* https://afham.brainsait.io/:splat 301!

# Legacy documentation redirects
/documentation/* /docs/:splat 301
/help/* /docs/:splat 301

# API proxy
/api/* https://api.afham.brainsait.io/:splat 200

# SPA fallback for docs
/docs/* /docs/index.html 200
EOF

    # Create _headers file
    cat > "$BUILD_DIR/_headers" << 'EOF'
# AFHAM Website Headers

/*
  X-Frame-Options: DENY
  X-Content-Type-Options: nosniff
  X-XSS-Protection: 1; mode=block
  Referrer-Policy: strict-origin-when-cross-origin
  Content-Security-Policy: default-src 'self'; script-src 'self' 'unsafe-inline' https://plausible.io https://cdnjs.cloudflare.com; style-src 'self' 'unsafe-inline' https://fonts.googleapis.com https://cdnjs.cloudflare.com; font-src 'self' https://fonts.gstatic.com; img-src 'self' data: https:; connect-src 'self' https://api.afham.brainsait.io https://plausible.io; frame-ancestors 'none';
  Permissions-Policy: camera=(), microphone=(), geolocation=()
  Strict-Transport-Security: max-age=31536000; includeSubDomains; preload

/assets/*
  Cache-Control: public, max-age=31536000, immutable

/docs/*
  Cache-Control: public, max-age=3600

/community/*
  Cache-Control: public, max-age=1800
EOF

    echo -e "${GREEN}✅ Rules configured${NC}"
}

# Validate deployment
validate_deployment() {
    echo -e "${YELLOW}🔍 Validating deployment...${NC}"
    
    # Wait a moment for deployment to propagate
    sleep 10
    
    # Check if main page is accessible
    if curl -f -s "https://$CUSTOM_DOMAIN" > /dev/null; then
        echo -e "${GREEN}✅ Main page accessible${NC}"
    else
        echo -e "${YELLOW}⚠️ Main page not yet accessible (may take a few minutes to propagate)${NC}"
    fi
    
    # Check if docs page is accessible
    if curl -f -s "https://$CUSTOM_DOMAIN/docs" > /dev/null; then
        echo -e "${GREEN}✅ Documentation page accessible${NC}"
    else
        echo -e "${YELLOW}⚠️ Documentation page not yet accessible${NC}"
    fi
    
    # Check if community page is accessible
    if curl -f -s "https://$CUSTOM_DOMAIN/community" > /dev/null; then
        echo -e "${GREEN}✅ Community page accessible${NC}"
    else
        echo -e "${YELLOW}⚠️ Community page not yet accessible${NC}"
    fi
}

# Cleanup
cleanup() {
    echo -e "${YELLOW}🧹 Cleaning up...${NC}"
    
    # Remove temporary files if any
    # (Currently no temp files to clean)
    
    echo -e "${GREEN}✅ Cleanup complete${NC}"
}

# Performance check
performance_check() {
    echo -e "${YELLOW}📊 Running performance check...${NC}"
    
    # Use Lighthouse CI if available
    if command -v lhci &> /dev/null; then
        echo "Running Lighthouse audit..."
        lhci autorun --upload.target=temporary-public-storage --collect.url="https://$CUSTOM_DOMAIN"
    else
        echo "Lighthouse CI not installed. Install with: npm install -g @lhci/cli"
    fi
    
    # Basic page speed test
    echo "Basic performance metrics:"
    curl -w "@-" -o /dev/null -s "https://$CUSTOM_DOMAIN" << 'EOF'
     time_namelookup:  %{time_namelookup}\n
        time_connect:  %{time_connect}\n
     time_appconnect:  %{time_appconnect}\n
    time_pretransfer:  %{time_pretransfer}\n
       time_redirect:  %{time_redirect}\n
  time_starttransfer:  %{time_starttransfer}\n
                     ----------\n
          time_total:  %{time_total}\n
EOF

    echo -e "${GREEN}✅ Performance check complete${NC}"
}

# Main deployment function
main() {
    echo -e "${BLUE}Starting deployment process...${NC}"
    
    check_env_vars
    install_dependencies
    prepare_build
    authenticate_cloudflare
    configure_rules
    deploy_to_pages
    configure_domain
    validate_deployment
    performance_check
    cleanup
    
    echo ""
    echo -e "${GREEN}🎉 AFHAM Website deployed successfully!${NC}"
    echo "========================================="
    echo -e "📱 Website URL: ${BLUE}https://$CUSTOM_DOMAIN${NC}"
    echo -e "📚 Documentation: ${BLUE}https://$CUSTOM_DOMAIN/docs${NC}"
    echo -e "💬 Community: ${BLUE}https://$CUSTOM_DOMAIN/community${NC}"
    echo ""
    echo -e "${YELLOW}🔧 Next steps:${NC}"
    echo "  1. Update DNS records to point to Cloudflare"
    echo "  2. Configure SSL/TLS settings in Cloudflare dashboard"
    echo "  3. Set up analytics and monitoring"
    echo "  4. Configure edge caching rules if needed"
    echo ""
    echo -e "${BLUE}🎯 Deployment complete!${NC}"
}

# Handle script arguments
case "${1:-}" in
    "help"|"--help"|"-h")
        echo "AFHAM Website Deployment Script"
        echo ""
        echo "Usage: $0 [command]"
        echo ""
        echo "Commands:"
        echo "  help         Show this help message"
        echo "  build-only   Only prepare the build directory"
        echo "  deploy-only  Only deploy (assumes build is ready)"
        echo "  validate     Only validate existing deployment"
        echo ""
        echo "Environment Variables Required:"
        echo "  CLOUDFLARE_ACCOUNT_ID  - Your Cloudflare account ID"
        echo "  CLOUDFLARE_API_TOKEN   - Your Cloudflare API token"
        echo ""
        echo "Examples:"
        echo "  export CLOUDFLARE_ACCOUNT_ID=your_account_id"
        echo "  export CLOUDFLARE_API_TOKEN=your_api_token"
        echo "  $0"
        ;;
    "build-only")
        echo -e "${BLUE}🏗️ Building only...${NC}"
        check_env_vars
        install_dependencies
        prepare_build
        configure_rules
        echo -e "${GREEN}✅ Build complete${NC}"
        ;;
    "deploy-only")
        echo -e "${BLUE}🚀 Deploying only...${NC}"
        check_env_vars
        authenticate_cloudflare
        deploy_to_pages
        configure_domain
        echo -e "${GREEN}✅ Deploy complete${NC}"
        ;;
    "validate")
        echo -e "${BLUE}🔍 Validating only...${NC}"
        validate_deployment
        performance_check
        echo -e "${GREEN}✅ Validation complete${NC}"
        ;;
    *)
        main
        ;;
esac