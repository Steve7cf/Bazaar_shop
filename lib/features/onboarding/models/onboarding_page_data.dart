class OnboardingPageData {
  final String lottieAsset;
  final String title;
  final String subtitle;

  const OnboardingPageData({
    required this.lottieAsset,
    required this.title,
    required this.subtitle,
  });
}

const onboardingPages = [
  OnboardingPageData(
    lottieAsset: 'assets/animations/onboarding_inventory.json',
    title: 'Run your shop, offline',
    subtitle:
        'Bazaar works with zero internet — sell, track stock, and manage debts fully on your device.',
  ),
  OnboardingPageData(
    lottieAsset: 'assets/animations/onboarding_sales.json',
    title: 'Fast sales, two tills',
    subtitle:
        'Ring up sales in seconds. General and Drinks tills are tracked separately, automatically.',
  ),
  OnboardingPageData(
    lottieAsset: 'assets/animations/onboarding_insights.json',
    title: 'Know your numbers',
    subtitle:
        'Real insights on trends, restocking, and debt risk — computed fresh from your own data.',
  ),
];
