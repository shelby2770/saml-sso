#!/bin/bash

# 🧪 Test YubiKey + Custom Attributes Flow

echo "╔══════════════════════════════════════════════════════════════════════════════╗"
echo "║              🧪 YubiKey + Custom Attributes Test Script                     ║"
echo "╚══════════════════════════════════════════════════════════════════════════════╝"
echo ""

cd "/home/shelby70/Projects/Django-SAML (2)"

echo "Step 1: Restart Django Service Providers..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Stop existing processes
echo "  🛑 Stopping SP1..."
pkill -f "runserver.*8001" 2>/dev/null
sleep 1

echo "  🛑 Stopping SP2..."
pkill -f "runserver.*8002" 2>/dev/null
sleep 1

# Start SP1
echo "  🚀 Starting SP1 on port 8001..."
nohup ./venv/bin/python manage.py runserver 127.0.0.1:8001 > sp1.log 2>&1 &
SP1_PID=$!
sleep 2

# Start SP2
echo "  🚀 Starting SP2 on port 8002..."
cd SAML_DJNAGO_2
nohup ../venv/bin/python manage.py runserver 127.0.0.1:8002 > ../sp2.log 2>&1 &
SP2_PID=$!
sleep 2
cd ..

echo ""
echo "✅ Services restarted!"
echo "   • SP1: PID $SP1_PID (port 8001)"
echo "   • SP2: PID $SP2_PID (port 8002)"
echo ""

echo "Step 2: Verify Services are Running..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
sleep 2

# Check SP1
if curl -s http://127.0.0.1:8001/ > /dev/null; then
    echo "  ✅ SP1 is accessible at http://127.0.0.1:8001"
else
    echo "  ❌ SP1 is not responding"
fi

# Check SP2
if curl -s http://127.0.0.1:8002/ > /dev/null; then
    echo "  ✅ SP2 is accessible at http://127.0.0.1:8002"
else
    echo "  ❌ SP2 is not responding"
fi

# Check Keycloak
if curl -s http://localhost:8080/ > /dev/null; then
    echo "  ✅ Keycloak is accessible at http://localhost:8080"
else
    echo "  ❌ Keycloak is not responding"
fi

echo ""
echo "Step 3: Test Instructions"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "🌐 Open one of these URLs in your browser:"
echo ""
echo "   SP1: http://127.0.0.1:8001/saml/login/"
echo "   SP2: http://127.0.0.1:8002/saml/login/"
echo ""
echo "🔐 Login with:"
echo "   Username: testuser"
echo "   Password: password123"
echo ""
echo "🔑 YubiKey (if registered):"
echo "   • Insert YubiKey when prompted"
echo "   • Touch it when LED blinks"
echo ""
echo "✨ Expected Result:"
echo "   You should see a success page displaying:"
echo "   • Username: testuser"
echo "   • Email: (your configured email)"
echo "   • Age: 30"
echo "   • Mobile: +1-555-0100"
echo "   • Address: 123 Main Street, New York, NY 10001"
echo "   • Profession: Software Developer"
echo ""
echo "📊 Console Logs:"
echo "   Server logs will show attribute details:"
echo ""
echo "   tail -f sp1.log"
echo "   tail -f sp2.log"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "🔍 Debugging:"
echo ""
echo "   View SP1 logs:  tail -f sp1.log"
echo "   View SP2 logs:  tail -f sp2.log"
echo "   View Keycloak:  docker logs -f keycloak-sso"
echo ""
echo "   Check processes: ps aux | grep runserver"
echo "   Stop SP1:        kill $SP1_PID"
echo "   Stop SP2:        kill $SP2_PID"
echo ""
echo "╔══════════════════════════════════════════════════════════════════════════════╗"
echo "║                         🚀 Ready to Test!                                    ║"
echo "║                                                                               ║"
echo "║  Open http://127.0.0.1:8001/saml/login/ in your browser                     ║"
echo "╚══════════════════════════════════════════════════════════════════════════════╝"
echo ""
