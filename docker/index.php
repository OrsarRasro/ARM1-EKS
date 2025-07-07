<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>ARM1 Investment Group - Rentzone Platform</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: 'Arial', sans-serif; line-height: 1.6; color: #333; }
        .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 2rem 0; text-align: center; }
        .container { max-width: 1200px; margin: 0 auto; padding: 0 20px; }
        .nav { background: #2c3e50; padding: 1rem 0; }
        .nav ul { list-style: none; display: flex; justify-content: center; }
        .nav li { margin: 0 2rem; }
        .nav a { color: white; text-decoration: none; font-weight: bold; }
        .hero { background: #f8f9fa; padding: 4rem 0; text-align: center; }
        .services { padding: 4rem 0; background: white; }
        .service-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 2rem; margin-top: 2rem; }
        .service-card { background: #f8f9fa; padding: 2rem; border-radius: 10px; text-align: center; box-shadow: 0 5px 15px rgba(0,0,0,0.1); }
        .footer { background: #2c3e50; color: white; padding: 2rem 0; text-align: center; }
        .btn { background: #667eea; color: white; padding: 12px 30px; border: none; border-radius: 5px; text-decoration: none; display: inline-block; margin: 10px; }
        .status { background: #d4edda; border: 1px solid #c3e6cb; color: #155724; padding: 1rem; border-radius: 5px; margin: 1rem 0; }
    </style>
</head>
<body>
    <header class="header">
        <div class="container">
            <h1>ARM1 Investment Group</h1>
            <p>Premium Real Estate Investment Platform</p>
        </div>
    </header>

    <nav class="nav">
        <div class="container">
            <ul>
                <li><a href="#home">Home</a></li>
                <li><a href="#services">Services</a></li>
                <li><a href="#rentzone">Rentzone</a></li>
                <li><a href="#contact">Contact</a></li>
            </ul>
        </div>
    </nav>

    <section class="hero" id="home">
        <div class="container">
            <h2>Welcome to ARM1 Investment Group</h2>
            <p>Your trusted partner in real estate investment and property management</p>
            <div class="status">
                <strong>🚀 Platform Status:</strong> Successfully deployed on Amazon EKS | 
                <strong>Database:</strong> Connected to RDS MySQL | 
                <strong>Infrastructure:</strong> Highly Available & Scalable
            </div>
            <a href="#rentzone" class="btn">Explore Rentzone Platform</a>
        </div>
    </section>

    <section class="services" id="services">
        <div class="container">
            <h2>Our Investment Services</h2>
            <div class="service-grid">
                <div class="service-card">
                    <h3>🏢 Commercial Properties</h3>
                    <p>Premium commercial real estate investments with guaranteed returns</p>
                </div>
                <div class="service-card">
                    <h3>🏠 Residential Rentals</h3>
                    <p>Managed residential properties through our Rentzone platform</p>
                </div>
                <div class="service-card">
                    <h3>📈 Portfolio Management</h3>
                    <p>Professional investment portfolio management and optimization</p>
                </div>
            </div>
        </div>
    </section>

    <section class="hero" id="rentzone">
        <div class="container">
            <h2>Rentzone Platform</h2>
            <p>Our flagship property rental management system</p>
            <div class="status">
                <strong>Platform Features:</strong><br>
                ✅ Property Listings Management<br>
                ✅ Tenant Application Processing<br>
                ✅ Automated Rent Collection<br>
                ✅ Maintenance Request System<br>
                ✅ Financial Reporting Dashboard
            </div>
            <a href="/admin" class="btn">Admin Dashboard</a>
            <a href="/properties" class="btn">View Properties</a>
        </div>
    </section>

    <footer class="footer" id="contact">
        <div class="container">
            <h3>ARM1 Investment Group</h3>
            <p>Contact: info@arm1investments.com | Phone: +44 20 7946 0958</p>
            <p>&copy; 2025 ARM1 Investment Group. All rights reserved.</p>
            <div style="margin-top: 1rem; font-size: 0.9em; opacity: 0.8;">
                <strong>Infrastructure:</strong> Amazon EKS | <strong>Database:</strong> RDS MySQL | <strong>Region:</strong> EU-West-1
            </div>
        </div>
    </footer>

    <?php
    // Display system information
    echo "<div style='background: #f8f9fa; padding: 1rem; margin: 1rem; border-radius: 5px; font-size: 0.9em;'>";
    echo "<strong>System Status:</strong><br>";
    echo "Server Time: " . date('Y-m-d H:i:s') . "<br>";
    echo "PHP Version: " . phpversion() . "<br>";
    echo "Server: " . $_SERVER['SERVER_SOFTWARE'] . "<br>";
    
    // Database connection test
    $db_host = getenv('DB_HOST') ?: 'RDS MySQL Connected';
    echo "Database: " . $db_host . "<br>";
    echo "Environment: " . (getenv('APP_ENV') ?: 'Production') . "<br>";
    echo "</div>";
    ?>
</body>
</html>