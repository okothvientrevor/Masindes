import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  // News outlets data
  final List<NewsOutlet> ugandaOutlets = [
    NewsOutlet(
      name: 'Daily Monitor',
      url: 'https://www.monitor.co.ug',
      logo: Icons.newspaper,
      color: Colors.blue[700]!,
    ),
    NewsOutlet(
      name: 'New Vision',
      url: 'https://www.newvision.co.ug',
      logo: Icons.visibility,
      color: Colors.green[700]!,
    ),
    NewsOutlet(
      name: 'The Observer',
      url: 'https://www.observer.ug',
      logo: Icons.article,
      color: Colors.orange[700]!,
    ),
    NewsOutlet(
      name: 'Nile Post',
      url: 'https://nilepost.co.ug',
      logo: Icons.public,
      color: Colors.purple[700]!,
    ),
    NewsOutlet(
      name: 'ChimpReports',
      url: 'https://chimpreports.com',
      logo: Icons.report,
      color: Colors.red[700]!,
    ),
    NewsOutlet(
      name: 'NTV Uganda',
      url: 'https://www.ntv.co.ug',
      logo: Icons.tv,
      color: Colors.indigo[700]!,
    ),
    NewsOutlet(
      name: 'NBS Television',
      url: 'https://www.nbstv.co.ug',
      logo: Icons.live_tv,
      color: Colors.teal[700]!,
    ),
  ];

  final List<NewsOutlet> kenyaOutlets = [
    NewsOutlet(
      name: 'Daily Nation',
      url: 'https://www.nation.co.ke',
      logo: Icons.flag,
      color: Colors.blue[800]!,
    ),
    NewsOutlet(
      name: 'The Standard',
      url: 'https://www.standardmedia.co.ke',
      logo: Icons.grade,
      color: Colors.green[800]!,
    ),
    NewsOutlet(
      name: 'The Star',
      url: 'https://www.the-star.co.ke',
      logo: Icons.star,
      color: Colors.yellow[700]!,
    ),
    NewsOutlet(
      name: 'Citizen Digital',
      url: 'https://www.citizendigital.co.ke',
      logo: Icons.people,
      color: Colors.orange[800]!,
    ),
    NewsOutlet(
      name: 'KBC',
      url: 'https://www.kbc.co.ke',
      logo: Icons.radio,
      color: Colors.red[800]!,
    ),
    NewsOutlet(
      name: 'Business Daily',
      url: 'https://www.businessdailyafrica.com',
      logo: Icons.business,
      color: Colors.purple[800]!,
    ),
    NewsOutlet(
      name: 'Tuko News',
      url: 'https://www.tuko.co.ke',
      logo: Icons.newspaper,
      color: Colors.cyan[700]!,
    ),
    NewsOutlet(
      name: 'Capital FM',
      url: 'https://www.capitalfm.co.ke',
      logo: Icons.radio_rounded,
      color: Colors.pink[700]!,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('East Africa News'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue[50]!, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue[600]!, Colors.blue[800]!],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      spreadRadius: 2,
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(Icons.public, size: 48, color: Colors.white),
                    const SizedBox(height: 12),
                    const Text(
                      'Stay Updated with East Africa News',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Access the latest news from Uganda and Kenya',
                      style: TextStyle(fontSize: 16, color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Uganda section
              _buildCountrySection(
                title: 'Uganda 🇺🇬',
                outlets: ugandaOutlets,
                flagColor: Colors.red,
              ),

              const SizedBox(height: 32),

              // Kenya section
              _buildCountrySection(
                title: 'Kenya 🇰🇪',
                outlets: kenyaOutlets,
                flagColor: Colors.green,
              ),

              const SizedBox(height: 32),

              // Footer
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(Icons.info_outline, color: Colors.grey[600], size: 32),
                    const SizedBox(height: 8),
                    Text(
                      'Tap any news outlet to read the latest news',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCountrySection({
    required String title,
    required List<NewsOutlet> outlets,
    required Color flagColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: flagColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: flagColor.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.language, color: flagColor, size: 24),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: flagColor.withOpacity(0.8),
                ),
              ),
              const Spacer(),
              Text(
                '${outlets.length} outlets',
                style: TextStyle(
                  fontSize: 14,
                  color: flagColor.withOpacity(0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // News outlets grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.2,
          ),
          itemCount: outlets.length,
          itemBuilder: (context, index) {
            return _buildNewsOutletCard(outlets[index]);
          },
        ),
      ],
    );
  }

  Widget _buildNewsOutletCard(NewsOutlet outlet) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => _openNewsWebView(outlet),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [Colors.white, outlet.color.withOpacity(0.05)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: outlet.color.withOpacity(0.2), width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon with background
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: outlet.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(outlet.logo, size: 32, color: outlet.color),
                ),

                const SizedBox(height: 12),

                // Outlet name
                Text(
                  outlet.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: outlet.color,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 8),

                // Read news indicator
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: outlet.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Read News',
                    style: TextStyle(
                      fontSize: 12,
                      color: outlet.color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openNewsWebView(NewsOutlet outlet) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WebViewScreen(
          title: outlet.name,
          url: outlet.url,
          color: outlet.color,
        ),
      ),
    );
  }
}

// News outlet model
class NewsOutlet {
  final String name;
  final String url;
  final IconData logo;
  final Color color;

  NewsOutlet({
    required this.name,
    required this.url,
    required this.logo,
    required this.color,
  });
}

// WebView screen for displaying news websites
class WebViewScreen extends StatefulWidget {
  final String title;
  final String url;
  final Color color;

  const WebViewScreen({
    super.key,
    required this.title,
    required this.url,
    required this.color,
  });

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late WebViewController controller;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              isLoading = true;
              errorMessage = null;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            setState(() {
              isLoading = false;
              errorMessage = 'Failed to load website: ${error.description}';
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(fontSize: 18)),
        backgroundColor: widget.color,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              controller.reload();
            },
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'forward':
                  controller.goForward();
                  break;
                case 'back':
                  controller.goBack();
                  break;
                case 'home':
                  controller.loadRequest(Uri.parse(widget.url));
                  break;
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'back',
                child: Row(
                  children: [
                    Icon(Icons.arrow_back, size: 20),
                    SizedBox(width: 8),
                    Text('Back'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'forward',
                child: Row(
                  children: [
                    Icon(Icons.arrow_forward, size: 20),
                    SizedBox(width: 8),
                    Text('Forward'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'home',
                child: Row(
                  children: [
                    Icon(Icons.home, size: 20),
                    SizedBox(width: 8),
                    Text('Home'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          if (errorMessage != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
                    const SizedBox(height: 16),
                    Text(
                      'Cannot load website',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      errorMessage!,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        _initializeWebView();
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Try Again'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.color,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            WebViewWidget(controller: controller),

          if (isLoading)
            Container(
              color: Colors.white,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(widget.color),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Loading ${widget.title}...',
                      style: TextStyle(
                        fontSize: 16,
                        color: widget.color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
