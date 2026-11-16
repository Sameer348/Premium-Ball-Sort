/// Purely cosmetic unlockables. Gameplay is never affected.
enum ShopCategory { ballSkin, tubeSkin, theme, booster }

enum BallSkin {
  classic('Classic', 0),
  glass('Glass', 300),
  crystal('Crystal', 600),
  neon('Neon', 800),
  candy('Candy', 500),
  metallic('Metallic', 900),
  galaxy('Galaxy', 1500, premium: true),
  pearl('Pearl', 700),
  fire('Fire', 1200, premium: true),
  ice('Ice', 1200, premium: true);

  const BallSkin(this.label, this.price, {this.premium = false});
  final String label;
  final int price;
  final bool premium;
  String get id => 'ball_$name';
}

enum TubeSkin {
  classicGlass('Classic Glass', 0),
  crystal('Crystal', 400),
  neonGlass('Neon Glass', 700),
  gold('Gold', 1500, premium: true),
  aurora('Aurora', 1100, premium: true),
  darkGlass('Dark Glass', 500),
  frosted('Frosted Glass', 600);

  const TubeSkin(this.label, this.price, {this.premium = false});
  final String label;
  final int price;
  final bool premium;
  String get id => 'tube_$name';
}

enum ThemeId {
  midnight('Midnight', 0),
  ocean('Ocean', 500),
  aurora('Aurora', 900, premium: true),
  candy('Candy', 600),
  sunset('Sunset', 700),
  galaxy('Galaxy', 1400, premium: true),
  forest('Forest', 600),
  minimal('Minimal', 400),
  cyber('Cyber', 1200, premium: true);

  const ThemeId(this.label, this.price, {this.premium = false});
  final String label;
  final int price;
  final bool premium;
  String get id => 'theme_$name';
}

/// Defaults are owned from the start.
const defaultOwnedItems = {'ball_classic', 'tube_classicGlass', 'theme_midnight'};
