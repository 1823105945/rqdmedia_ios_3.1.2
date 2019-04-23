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

#define krqdMediaSettingPasscodeOnKey @"PasscodeProtection"
#define krqdMediaSettingPasscodeAllowTouchID @"AllowTouchID"
#define krqdMediaSettingPasscodeAllowFaceID @"AllowFaceID"
#define krqdMediaAutomaticallyPlayNextItem @"AutomaticallyPlayNextItem"
#define krqdMediaSettingContinueAudioInBackgroundKey @"BackgroundAudioPlayback"
#define krqdMediaSettingStretchAudio @"audio-time-stretch"
#define krqdMediaSettingStretchAudioOnValue @"1"
#define krqdMediaSettingStretchAudioOffValue @"0"
#define krqdMediaSettingTextEncoding @"subsdec-encoding"
#define krqdMediaSettingTextEncodingDefaultValue @"Windows-1252"
#define krqdMediaSettingSkipLoopFilter @"avcodec-skiploopfilter"
#define krqdMediaSettingSkipLoopFilterNone @(0)
#define krqdMediaSettingSkipLoopFilterNonRef @(1)
#define krqdMediaSettingSaveHTTPUploadServerStatus @"isHTTPServerOn"
#define krqdMediaSettingSubtitlesFont @"quartztext-font"
#define krqdMediaSettingSubtitlesFontDefaultValue @"HelveticaNeue"
#define krqdMediaSettingSubtitlesFontSize @"quartztext-rel-fontsize"
#define krqdMediaSettingSubtitlesFontSizeDefaultValue @"16"
#define krqdMediaSettingSubtitlesBoldFont @"quartztext-bold"
#define krqdMediaSettingSubtitlesBoldFontDefaultValue @NO
#define krqdMediaSettingSubtitlesFontColor @"quartztext-color"
#define krqdMediaSettingSubtitlesFontColorDefaultValue @"16777215"
#define krqdMediaSettingSubtitlesFilePath @"sub-file"
#define krqdMediaSettingDeinterlace @"deinterlace"
#define krqdMediaSettingDeinterlaceDefaultValue @(0)
#define krqdMediaSettingHardwareDecoding @"codec"
#define krqdMediaSettingHardwareDecodingDefault @""
#define krqdMediaSettingNetworkCaching @"network-caching"
#define krqdMediaSettingNetworkCachingDefaultValue @(999)
#define krqdMediaSettingsDecrapifyTitles @"MLDecrapifyTitles"
#define krqdMediaSettingVolumeGesture @"EnableVolumeGesture"
#define krqdMediaSettingPlayPauseGesture @"EnablePlayPauseGesture"
#define krqdMediaSettingBrightnessGesture @"EnableBrightnessGesture"
#define krqdMediaSettingSeekGesture @"EnableSeekGesture"
#define krqdMediaSettingCloseGesture @"EnableCloseGesture"
#define krqdMediaSettingVariableJumpDuration @"EnableVariableJumpDuration"
#define krqdMediaSettingVideoFullscreenPlayback @"AlwaysUseFullscreenForVideo"
#define krqdMediaSettingContinuePlayback @"ContinuePlayback"
#define krqdMediaSettingContinueAudioPlayback @"ContinueAudioPlayback"
#define krqdMediaSettingFTPTextEncoding @"ftp-text-encoding"
#define krqdMediaSettingFTPTextEncodingDefaultValue @(5) // ISO Latin 1
#define krqdMediaSettingPlaybackSpeedDefaultValue @"playback-speed"
#define krqdMediaSettingWiFiSharingIPv6 @"wifi-sharing-ipv6"
#define krqdMediaSettingWiFiSharingIPv6DefaultValue @(NO)
#define krqdMediaSettingEqualizerProfile @"EqualizerProfile"
#define krqdMediaSettingEqualizerProfileDefaultValue @(0)
#define krqdMediaSettingPlaybackForwardSkipLength @"playback-forward-skip-length"
#define krqdMediaSettingPlaybackForwardSkipLengthDefaultValue @(60)
#define krqdMediaSettingPlaybackBackwardSkipLength @"playback-forward-skip-length"
#define krqdMediaSettingPlaybackBackwardSkipLengthDefaultValue @(60)
#define krqdMediaSettingOpenAppForPlayback @"open-app-for-playback"
#define krqdMediaSettingOpenAppForPlaybackDefaultValue @YES

#define krqdMediaShowRemainingTime @"show-remaining-time"
#define krqdMediaRecentURLs @"recent-urls"
#define krqdMediaRecentURLTitles @"recent-url-titles"
#define krqdMediaPrivateWebStreaming @"private-streaming"
#define krqdMediahttpScanSubtitle @"http-scan-subtitle"

#define kSupportedFileExtensions @"\\.(3g2|3gp|3gp2|3gpp|amv|asf|avi|bik|bin|crf|divx|drc|dv|evo|f4v|flv|gvi|gxf|iso|m1v|m2v|m2t|m2ts|m4v|mkv|mov|mp2|mp2v|mp4|mp4v|mpe|mpeg|mpeg1|mpeg2|mpeg4|mpg|mpv2|mts|mtv|mxf|mxg|nsv|nuv|ogg|ogm|ogv|ogx|ps|rec|rm|rmvb|rpl|thp|tod|ts|tts|txd|rqdmedia|vob|vro|webm|wm|wmv|wtv|xesc)$"
#define kSupportedSubtitleFileExtensions @"\\.(cdg|idx|srt|sub|utf|ass|ssa|aqt|jss|psb|rt|smi|txt|smil|stl|usf|dks|pjs|mpl2|mks|vtt|ttml|dfxp)$"
#define kSupportedAudioFileExtensions @"\\.(3ga|669|a52|aac|ac3|adt|adts|aif|aifc|aiff|amb|amr|aob|ape|au|awb|caf|dts|flac|it|kar|m4a|m4b|m4p|m5p|mid|mka|mlp|mod|mpa|mp1|mp2|mp3|mpc|mpga|mus|oga|ogg|oma|opus|qcp|ra|rmi|s3m|sid|spx|tak|thd|tta|voc|vqf|w64|wav|wma|wv|xa|xm)$"
#define kSupportedPlaylistFileExtensions @"\\.(asx|b4s|cue|ifo|m3u|m3u8|pls|ram|rar|sdp|rqdmedia|xspf|wax|wvx|zip|conf)$"

#define krqdMediaDarwinNotificationNowPlayingInfoUpdate @"org.videolan.ios-app.nowPlayingInfoUpdate"

#if TARGET_IPHONE_SIMULATOR
#define WifiInterfaceName @"en1"
#else
#define WifiInterfaceName @"en0"
#endif

#define krqdMediaMigratedToUbiquitousStoredServerList @"krqdMediaMigratedToUbiquitousStoredServerList"
#define krqdMediaStoredServerList @"krqdMediaStoredServerList"
#define krqdMediaStoreDropboxCredentials @"krqdMediaStoreDropboxCredentials"
#define krqdMediaStoreOneDriveCredentials @"krqdMediaStoreOneDriveCredentials"
#define krqdMediaStoreBoxCredentials @"krqdMediaStoreBoxCredentials"
#define krqdMediaStoreGDriveCredentials @"krqdMediaStoreGDriveCredentials"

#define krqdMediaUserActivityPlaying @"org.videolan.rqdmedia-ios.playing"
#define krqdMediaUserActivityLibrarySelection @"org.videolan.rqdmedia-ios.libraryselection"
#define krqdMediaUserActivityLibraryMode @"org.videolan.rqdmedia-ios.librarymode"

#define krqdMediaApplicationShortcutLocalLibrary @"ApplicationShortcutLocalLibrary"
#define krqdMediaApplicationShortcutLocalServers @"ApplicationShortcutLocalServers"
#define krqdMediaApplicationShortcutOpenNetworkStream @"ApplicationShortcutOpenNetworkStream"
#define krqdMediaApplicationShortcutClouds @"ApplicationShortcutClouds"

/* LEGACY KEYS, DO NOT USE IN NEW CODE */
#define krqdMediaFTPServer @"ftp-server"
#define krqdMediaFTPLogin @"ftp-login"
#define krqdMediaFTPPassword @"ftp-pass"
#define krqdMediaPLEXServer @"plex-server"
#define krqdMediaPLEXPort @"plex-port"
