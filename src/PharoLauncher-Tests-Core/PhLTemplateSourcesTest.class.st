Class {
	#name : #PhLTemplateSourcesTest,
	#superclass : #TestCase,
	#instVars : [
		'sourcesFile',
		'defaultPharoLauncherApp'
	],
	#category : #'PharoLauncher-Tests-Core'
}

{ #category : #running }
PhLTemplateSourcesTest >> setUp [
	super setUp.
	sourcesFile := FileSystem memory / 'templates-sources.test'.
	"Avoid blocking modal dialogs when a source update is available"
	defaultPharoLauncherApp := PharoLauncherApplication default.
	PharoLauncherApplication default: PhLTestApplication new. 
]

{ #category : #running }
PhLTemplateSourcesTest >> tearDown [
	PhLPharoTemplateSources resetSourcesUrl.
	PharoLauncherApplication default: defaultPharoLauncherApp.
	super tearDown
]

{ #category : #tests }
PhLTemplateSourcesTest >> testAlmostIdenticalTemplateSourcesAreDifferent [
	| templatesSources1 templatesSources2 |
	templatesSources1 := (PhLPharoTemplateSources withTemplateList: PhLPharoTemplateSources defaultSources) sources.
	templatesSources2 := (PhLPharoTemplateSources withTemplateList: PhLPharoTemplateSources defaultSources) sources.
	templatesSources2 second templates first name: 'changed'.

	self deny: templatesSources1 equals: templatesSources2
]

{ #category : #tests }
PhLTemplateSourcesTest >> testCanCreateInstanceFromAListOfTemplateSource [
	| tplSources sources |
	
	tplSources := PhLTemplateSources withTemplateList: { PhLTemplateSource officialDistributionsGroup }.
	sources := tplSources sources.
	
	self 
		assert: sources size
		equals: 1
	
]

{ #category : #tests }
PhLTemplateSourcesTest >> testCanFetchSourcesFileWhenAbsent [
	self deny: sourcesFile exists.
	
	(PhLPharoTemplateSources withFile: sourcesFile) ensureSourcesFile. 
	
	self assert: sourcesFile exists
]

{ #category : #tests }
PhLTemplateSourcesTest >> testGivenUserSourcesFileAbsentWhenAskingUserSourcesThenGetEmptyCollection [
	| sources |
	self deny: sourcesFile exists.

	sources := (PhLUserTemplateSources withFile: sourcesFile) sources.

	self assertEmpty: sources
]

{ #category : #tests }
PhLTemplateSourcesTest >> testGivenUserSourcesFileWithErrorsWhenAskingUserSourcesThenGetEmptyCollection [
	| sources |
	sourcesFile writeStreamDo: [ :stream | stream nextPutAll: 'foobar' ].

	sources := (PhLTemplateSources withFile: sourcesFile) sources.

	self assertEmpty: sources
]

{ #category : #tests }
PhLTemplateSourcesTest >> testGivenUserSourcesFileWithReferencesToUnknownVariablesWhenAskingUserSourcesThenGetEmptyCollection [
	| sources |
	sourcesFile writeStreamDo: [ :stream | stream nextPutAll: '[PhLHTTPListingTemplateGroup{#nonexistingiv:''http://foo.org'',#name:''foo''}]' ].

	self shouldnt: [ sources := (PhLTemplateSources withFile: sourcesFile) sources ] raise: InstanceVariableNotFound.

	self assertEmpty: sources
]

{ #category : #tests }
PhLTemplateSourcesTest >> testIdenticalTemplateSourcesAreEquals [
	| templatesSources1 templatesSources2 |
	templatesSources1 := (PhLTemplateSources withTemplateList: PhLPharoTemplateSources defaultSources) sources.
	templatesSources2 := (PhLTemplateSources withTemplateList: PhLPharoTemplateSources defaultSources) sources.
	
	self 
		assert: templatesSources1
		equals: templatesSources2
	
]

{ #category : #tests }
PhLTemplateSourcesTest >> testNoUpdateAnnouncedWhenDownloadedSourcesIsSameAsSources [
	| announcements sources |
	sourcesFile writeStreamDo: [ :stream | stream nextPutAll: (STON toString: true) ].

	announcements := OrderedCollection new.
	ZnClientTest new
		withServerDo: [ :server | 
			server onRequestRespond: [ :request | ZnResponse ok: (ZnEntity text: (STON toString: true)) ].

			sources := PhLPharoTemplateSources withFile: sourcesFile.
			PhLPharoTemplateSources sourcesUrl: server localUrl.

			PhLPharoTemplateSources announcer weak when: PhLSourcesFileUpdateAvailable send: #add: to: announcements.

			sources checkForUpdates.

			self assertEmpty: announcements ]
]

{ #category : #tests }
PhLTemplateSourcesTest >> testSourcesFileNotFetchIfPresentWhenCallingEnsureSourcesFile [
	sourcesFile ensureCreateFile.	
	
	(PhLPharoTemplateSources withFile: sourcesFile) ensureSourcesFile. 
	
	self 
		assert: sourcesFile parent children size
		equals: 1
]

{ #category : #tests }
PhLTemplateSourcesTest >> testSourcesFileNotUpdatedWhenDownloadedSourcesFileIsAbsent [
	| sources sourcesFileModificationTime |
	sourcesFile writeStreamDo: [ :stream | stream nextPutAll: 'foobar' ].
	sourcesFileModificationTime := sourcesFile modificationTime.

	sources := PhLPharoTemplateSources withFile: sourcesFile.
	sources downloadedSourcesFile ensureDelete.
	
	sources updateSourcesFile.
	
	self 
		assert: sources file modificationTime 
		equals: sourcesFileModificationTime
]

{ #category : #tests }
PhLTemplateSourcesTest >> testSourcesFileUpdateAvailableIsAnnouncedWhenDownloadedSourcesDifferentFromSources [
	| announcements sources |
	
	sourcesFile writeStreamDo: [ :stream | stream nextPutAll: (STON toString: true) ].
	
	announcements := OrderedCollection new. 
	ZnClientTest new 
	withServerDo: [ :server |
		server onRequestRespond: [ :request | 
			ZnResponse ok: (ZnEntity text: (STON toString: false)) ].
		
	sources := PhLPharoTemplateSources withFile: sourcesFile.
	PhLPharoTemplateSources sourcesUrl: server localUrl.
	
	PhLPharoTemplateSources announcer weak
		when: PhLSourcesFileUpdateAvailable
		send: #add:
		to: announcements.

	sources checkForUpdates.

	self 
		assert: announcements size 
		equals: 1 ].
]

{ #category : #tests }
PhLTemplateSourcesTest >> testUserTemplatesAreListedAfterPharoTemplates [
	| userSources pharoSources sources |
	userSources := PhLUserTemplateSources example.
	pharoSources := PhLPharoTemplateSources fromFile.
	
	sources := (PhLCompositeTemplateSources new initializeWith: { pharoSources . userSources }) sources.
	
	self 
		assert: sources size
		equals: pharoSources sources size + 1.
	self 
		assert: sources last
		equals: userSources sources last
]
