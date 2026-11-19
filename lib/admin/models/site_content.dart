class SiteServiceItem {
  final String id;
  final String title;
  final String titleTa;
  final String detail;
  final String detailTa;

  const SiteServiceItem({
    required this.id,
    required this.title,
    required this.titleTa,
    required this.detail,
    required this.detailTa,
  });

  factory SiteServiceItem.fromJson(Map<String, dynamic> json) {
    return SiteServiceItem(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      titleTa: json['titleTa'] as String? ?? '',
      detail: json['detail'] as String? ?? '',
      detailTa: json['detailTa'] as String? ?? '',
    );
  }
}

class SiteFeatureItem {
  final String id;
  final String label;
  final String labelTa;
  final bool enabled;

  const SiteFeatureItem({
    required this.id,
    required this.label,
    required this.labelTa,
    required this.enabled,
  });

  factory SiteFeatureItem.fromJson(Map<String, dynamic> json) {
    return SiteFeatureItem(
      id: json['id'] as String? ?? '',
      label: json['label'] as String? ?? '',
      labelTa: json['labelTa'] as String? ?? '',
      enabled: json['enabled'] as bool? ?? true,
    );
  }
}

class SiteContent {
  final String eyebrow;
  final String headline;
  final String headlineTa;
  final String lead;
  final String leadTa;
  final bool showSubscriberCta;
  final String subscriberCtaLabel;
  final String subscriberCtaLabelTa;
  final String subscriberCtaDetail;
  final String subscriberCtaDetailTa;
  final bool showMemberCta;
  final String memberCtaLabel;
  final String memberCtaLabelTa;
  final String memberCtaDetail;
  final String memberCtaDetailTa;
  final List<SiteServiceItem> services;
  final List<SiteFeatureItem> features;
  final bool showAi;
  final String aiKicker;
  final String aiTitle;
  final String aiTitleTa;
  final String aiBody;
  final String aiBodyTa;
  final String privacyPolicy;
  final String privacyPolicyTa;
  final String cookiePolicy;
  final String cookiePolicyTa;

  const SiteContent({
    required this.eyebrow,
    required this.headline,
    required this.headlineTa,
    required this.lead,
    required this.leadTa,
    required this.showSubscriberCta,
    required this.subscriberCtaLabel,
    required this.subscriberCtaLabelTa,
    required this.subscriberCtaDetail,
    required this.subscriberCtaDetailTa,
    required this.showMemberCta,
    required this.memberCtaLabel,
    required this.memberCtaLabelTa,
    required this.memberCtaDetail,
    required this.memberCtaDetailTa,
    required this.services,
    required this.features,
    required this.showAi,
    required this.aiKicker,
    required this.aiTitle,
    required this.aiTitleTa,
    required this.aiBody,
    required this.aiBodyTa,
    required this.privacyPolicy,
    required this.privacyPolicyTa,
    required this.cookiePolicy,
    required this.cookiePolicyTa,
  });

  factory SiteContent.fromJson(Map<String, dynamic> json) {
    return SiteContent(
      eyebrow: json['eyebrow'] as String? ?? 'Airo Techhub',
      headline: json['headline'] as String? ?? 'A workspace for groups, learning, and payments.',
      headlineTa: json['headlineTa'] as String? ?? 'குழுக்கள், கற்றல் மற்றும் கட்டணங்களுக்கான பணித்தளம்.',
      lead: json['lead'] as String? ?? 'A subscriber opens a workspace. A member joins a group with a code from that workspace.',
      leadTa: json['leadTa'] as String? ?? 'சந்தாதாரர் ஒரு பணித்தளத்தைத் திறக்கிறார். உறுப்பினர் அந்தப் பணித்தளத்தின் குறியீட்டுடன் ஒரு குழுவில் சேருகிறார்.',
      showSubscriberCta: json['showSubscriberCta'] as bool? ?? true,
      subscriberCtaLabel: json['subscriberCtaLabel'] as String? ?? 'Register as a subscriber',
      subscriberCtaLabelTa: json['subscriberCtaLabelTa'] as String? ?? 'சந்தாதாரராக பதிவு செய்யுங்கள்',
      subscriberCtaDetail: json['subscriberCtaDetail'] as String? ?? 'Open a workspace, then invite members into your groups.',
      subscriberCtaDetailTa: json['subscriberCtaDetailTa'] as String? ?? 'ஒரு பணித்தளத்தைத் திறந்து, உங்கள் குழுக்களுக்கு உறுப்பினர்களை அழையுங்கள்.',
      showMemberCta: json['showMemberCta'] as bool? ?? true,
      memberCtaLabel: json['memberCtaLabel'] as String? ?? 'Join your group',
      memberCtaLabelTa: json['memberCtaLabelTa'] as String? ?? 'உங்கள் குழுவில் சேருங்கள்',
      memberCtaDetail: json['memberCtaDetail'] as String? ?? 'Members register with the code from their group admin.',
      memberCtaDetailTa: json['memberCtaDetailTa'] as String? ?? 'உறுப்பினர்கள் தங்கள் குழு நிர்வாகி கொடுத்த குறியீட்டுடன் பதிவு செய்கிறார்கள்.',
      services: (json['services'] as List<dynamic>?)
              ?.map((e) => SiteServiceItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      features: (json['features'] as List<dynamic>?)
              ?.map((e) => SiteFeatureItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      showAi: json['showAi'] as bool? ?? true,
      aiKicker: json['aiKicker'] as String? ?? 'AI',
      aiTitle: json['aiTitle'] as String? ?? 'AI Teacher',
      aiTitleTa: json['aiTitleTa'] as String? ?? 'AI ஆசிரியர்',
      aiBody: json['aiBody'] as String? ?? 'Ask a question, set an exam, or write notes. It works in English and Tamil.',
      aiBodyTa: json['aiBodyTa'] as String? ?? 'கேள்வி கேளுங்கள், தேர்வு அமையுங்கள், அல்லது குறிப்பு எழுதுங்கள்.',
      privacyPolicy: json['privacyPolicy'] as String? ?? '',
      privacyPolicyTa: json['privacyPolicyTa'] as String? ?? '',
      cookiePolicy: json['cookiePolicy'] as String? ?? '',
      cookiePolicyTa: json['cookiePolicyTa'] as String? ?? '',
    );
  }
}

