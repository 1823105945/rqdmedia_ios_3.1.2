/*****************************************************************************
 * rqdMediaConstants.h
 * rqdMedia for iOS
 *****************************************************************************
 * Copyright (c) 2013-2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *          Jean-Romain Prévost <jr # 3on.fr>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#define krqdMediaVersionCodename @"All Along the Watchtower"

#define krqdMediaRecentURLs @"recent-urls"
#define krqdMediaRecentURLTitles @"recent-url-titles"
#define krqdMediaStoreDropboxCredentials @"krqdMediaStoreDropboxCredentials"
#define krqdMediaStoreOneDriveCredentials @"krqdMediaStoreOneDriveCredentials"
#define krqdMediaStoreBoxCredentials @"krqdMediaStoreBoxCredentials"
#define krqdMediaStoreGDriveCredentials @"krqdMediaStoreGDriveCredentials"

#define kSupportedFileExtensions @"\\.(3g2|3gp|3gp2|3gpp|amv|asf|avi|bik|bin|crf|divx|drc|dv|evo|f4v|flv|gvi|gxf|iso|m1v|m2v|m2t|m2ts|m4v|mkv|mov|mp2|mp2v|mp4|mp4v|mpe|mpeg|mpeg1|mpeg2|mpeg4|mpg|mpv2|mts|mtv|mxf|mxg|nsv|nuv|ogg|ogm|ogv|ogx|ps|rec|rm|rmvb|rpl|thp|tod|ts|tts|txd|vob|vro|webm|wm|wmv|wtv|xesc)$"
#define kSupportedSubtitleFileExtensions @"\\.(cdg|idx|srt|sub|utf|ass|ssa|aqt|jss|psb|rt|smi|txt|smil|stl|usf|dks|pjs|mpl2|mks|vtt|ttml|dfxp)$"
#define kSupportedAudioFileExtensions @"\\.(3ga|669|a52|aac|ac3|adt|adts|aif|aifc|aiff|amb|amr|aob|ape|au|awb|caf|dts|flac|it|kar|m4a|m4b|m4p|m5p|mid|mka|mlp|mod|mpa|mp1|mp2|mp3|mpc|mpga|mus|oga|ogg|oma|opus|qcp|ra|rmi|s3m|sid|spx|tak|thd|tta|voc|vqf|w64|wav|wma|wv|xa|xm)$"
#define kSupportedPlaylistFileExtensions @"\\.(asx|b4s|cue|ifo|m3u|m3u8|pls|ram|rar|sdp|rqdmedia|xspf|wax|wvx|zip|conf)$"

#define krqdMediaSettingPlaybackSpeedDefaultValue @"playback-speed"
#define krqdMediaSettingNetworkCaching @"network-caching"
#define krqdMediaSettingNetworkCachingDefaultValue @(999)
#define krqdMediaSettingSkipLoopFilter @"avcodec-skiploopfilter"
#define krqdMediaSettingSkipLoopFilterNone @(0)
#define krqdMediaSettingSkipLoopFilterNonRef @(1)
#define krqdMediaSettingSkipLoopFilterNonKey @(3)
#define krqdMediaSettingDeinterlace @"deinterlace"
#define krqdMediaSettingDeinterlaceDefaultValue @(0)
#define krqdMediaSettingHardwareDecoding @"codec"
#define krqdMediaSettingHardwareDecodingDefault @""
#define krqdMediaSettingSubtitlesFont @"quartztext-font"
#define krqdMediaSettingSubtitlesFontDefaultValue @"HelveticaNeue"
#define krqdMediaSettingSubtitlesFontSize @"quartztext-rel-fontsize"
#define krqdMediaSettingSubtitlesFontSizeDefaultValue @"16"
#define krqdMediaSettingSubtitlesBoldFont @"quartztext-bold"
#define krqdMediaSettingSubtitlesBoldFontDefaultValue @NO
#define krqdMediaSettingSubtitlesFontColor @"quartztext-color"
#define krqdMediaSettingSubtitlesFontColorDefaultValue @"16777215"
#define krqdMediaSettingTextEncoding @"subsdec-encoding"
#define krqdMediaSettingTextEncodingDefaultValue @"Windows-1252"
#define krqdMediaSettingStretchAudio @"audio-time-stretch"
#define krqdMediaSettingStretchAudioOnValue @"1"
#define krqdMediaSettingStretchAudioOffValue @"0"
#define krqdMediaSettingContinueAudioInBackgroundKey @"BackgroundAudioPlayback"
#define krqdMediaSettingSubtitlesFilePath @"sub-file"
#define krqdMediaSettingEqualizerProfile @"EqualizerProfile"
#define krqdMediaSettingEqualizerProfileDefaultValue @(0)
#define krqdMediaSettingPlaybackForwardSkipLength @"playback-forward-skip-length"
#define krqdMediaSettingPlaybackForwardSkipLengthDefaultValue @(60)
#define krqdMediaSettingPlaybackBackwardSkipLength @"playback-forward-skip-length"
#define krqdMediaSettingPlaybackBackwardSkipLengthDefaultValue @(60)
#define krqdMediaSettingFTPTextEncoding @"ftp-text-encoding"
#define krqdMediaSettingFTPTextEncodingDefaultValue @(5) // ISO Latin 1
#define krqdMediaSettingSaveHTTPUploadServerStatus @"isHTTPServerOn"
#define krqdMediaAutomaticallyPlayNextItem @"AutomaticallyPlayNextItem"
#define krqdMediaSettingDownloadArtwork @"download-artwork"
#define krqdMediaSettingUseSPDIF @"krqdMediaSettingUseSPDIF"

#define krqdMediaSettingLastUsedSubtitlesSearchLanguage @"krqdMediaSettingLastUsedSubtitlesSearchLanguage"
#define krqdMediaSettingWiFiSharingIPv6 @"wifi-sharing-ipv6"
#define krqdMediaSettingWiFiSharingIPv6DefaultValue @(NO)

#define krqdMediafortvOSMovieDBKey @""
