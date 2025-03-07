"
I'm in charge of selecting the appropriate Virtual Machine for a given image. If the required virtual machine is not found on disk, I will download it from http://files.pharo.org.
I determine the VM to use by reading the image file header.
"
Class {
	#name : #PhLVirtualMachineManager,
	#superclass : #Object,
	#instVars : [
		'imageFile',
		'imageFormatNumber',
		'imageVersion'
	],
	#classInstVars : [
		'vmStore'
	],
	#category : #'PharoLauncher-Core-Download'
}

{ #category : #unzipping }
PhLVirtualMachineManager class >> canUseSytemZip [
	^ PhLProcessWrapper isCommandAvailable: 'unzip'
]

{ #category : #private }
PhLVirtualMachineManager class >> fetch: aVmUrl to: targetFile [
	PhLDownloadManager default 
		download: aVmUrl
		toFile: targetFile.
	self
		unzip: targetFile
		to: (targetFile parent / targetFile basenameWithoutExtension)
]

{ #category : #'instance creation' }
PhLVirtualMachineManager class >> forImage: aPharoImagePathOrFileReference [
	^ self new 
		imageFile: aPharoImagePathOrFileReference asFileReference;
		yourself
		
		
]

{ #category : #accessing }
PhLVirtualMachineManager class >> imageFormat32bits [
	^ 6521
]

{ #category : #accessing }
PhLVirtualMachineManager class >> imageFormat64bits [
	^ 68021
]

{ #category : #accessing }
PhLVirtualMachineManager class >> imageFormat6504 [
	^ 6504
]

{ #category : #querying }
PhLVirtualMachineManager class >> imageFormatNumberFromFile: anImagePath [
	| imageFile |
	imageFile := anImagePath asFileReference.
	imageFile exists ifFalse: [
		self error: imageFile fullName, ' does not exist.' ].
	^ imageFile binaryReadStreamDo: [ :stream | self imageFormatNumberFromStream: stream ].

]

{ #category : #private }
PhLVirtualMachineManager class >> imageFormatNumberFromStream: aStream [
	| number |
	number := aStream nextLittleEndianNumber: 4.
	aStream close.
	^ number
]

{ #category : #accessing }
PhLVirtualMachineManager class >> imageFormatPreSpur [
	^ 6505
]

{ #category : #testing }
PhLVirtualMachineManager class >> is32bits: anImageFormatVersion [
	"32 bits Spur image format"

	^ anImageFormatVersion = self imageFormat32bits
]

{ #category : #testing }
PhLVirtualMachineManager class >> is64bits [
	^ self is64bits: Smalltalk image imageFormatVersion
]

{ #category : #testing }
PhLVirtualMachineManager class >> is64bits: anImageFormatVersion [
	"64 bits Spur image format"

	^ anImageFormatVersion = self imageFormat64bits
]

{ #category : #testing }
PhLVirtualMachineManager class >> isPreSpur: anImageFormatVersion [
	"Pre-Spur image format"

	^ anImageFormatVersion = self imageFormatPreSpur
]

{ #category : #unzipping }
PhLVirtualMachineManager class >> pharoUnzip: aZipFileReference to: outputDirectory [
	
	PharoLauncherApplication default 
		pushProgress: ('Unzipping {1}' format: { aZipFileReference basename })
		with: [ :bar |
			ZipArchive new
				readFrom: aZipFileReference;
				extractAllTo: outputDirectory 
					informing: bar 
					overwrite: true ]
]

{ #category : #private }
PhLVirtualMachineManager class >> privateVmStore [
	"The private store is used to fetch one VM per image format and open image to determine their pharo version number (e.g. 6.0, 7.0, etc.). Then we download the latest stable VM for the given Pharo image version."
	^ (self vmStore / 'private') ensureCreateDirectory
]

{ #category : #initialization }
PhLVirtualMachineManager class >> reset [
	<script>
	vmStore := nil
]

{ #category : #settings }
PhLVirtualMachineManager class >> settingsOn: aBuilder [
	<systemsettings>
	<pharoLauncherSettings>
	(aBuilder setting: #vmStoreString)
		label: 'VMs Directory' translated;
		type: #Directory;
		parent: #pharoLauncher;
		target: self;
		order: 50;
		default: (FileLocator launcherUserFilesLocation / 'vms');
		description:
			'Path to the directory containing all the VMs to launch your Pharo images.' , String cr
				, 'You must have the read/write rights on this folder.' , String cr
				, 'NOTE: This path might need to escape some whitespace characters e.g. "/Pharo\ 3.0/Pharo".' translated
]

{ #category : #unzipping }
PhLVirtualMachineManager class >> systemUnzip: aZipFileReference to: outputDirectory [
	PhLProcessWrapper new 
		shellCommand;
		addArguments: 'unzip -o -d';
		addArgument: outputDirectory fullName surroundedByDoubleQuotes;
		addArgument: aZipFileReference fullName surroundedByDoubleQuotes;
		in: [ :process |
				"on Windows, unzip logs can corrupt extracted files. 
				See https://github.com/pharo-project/pharo-launcher/issues/349"
				OSPlatform current isWindows
					ifTrue: [ process addArgument: ' > nul' ] ];
		runAndWait.
]

{ #category : #unzipping }
PhLVirtualMachineManager class >> unzip: aZipFileReference to: outputDirectory [
	outputDirectory ensureCreateDirectory.
	self canUseSytemZip
		ifTrue: [ self systemUnzip: aZipFileReference to: outputDirectory ]
		ifFalse: [ self pharoUnzip: aZipFileReference to: outputDirectory ]
]

{ #category : #accessing }
PhLVirtualMachineManager class >> vmStore [
	^ vmStore ifNil: [ vmStore := (FileLocator launcherUserFilesLocation / 'vms') ensureCreateDirectory ]
]

{ #category : #accessing }
PhLVirtualMachineManager class >> vmStore: anObject [
	vmStore := anObject asFileReference.
	vmStore ensureCreateDirectory
]

{ #category : #accessing }
PhLVirtualMachineManager class >> vmStoreString [
	" Used to display a nice file url in settings browser"
	^ self vmStore pathString 
]

{ #category : #accessing }
PhLVirtualMachineManager class >> vmStoreString: aFileUrl [
	" Used to display a nice file url in settings browser"
	self vmStore: aFileUrl

]

{ #category : #querying }
PhLVirtualMachineManager >> availableVirtualMachines [
	^ self availableVirtualMachinesIn: self vmStore
]

{ #category : #querying }
PhLVirtualMachineManager >> availableVirtualMachinesByImageFormat [
	^ [ self availableVirtualMachinesIn: self privateVmStore] 
		on: PhLExecutableNotFoundError 
		do: [ :ex | ex path asFileReference ensureDeleteAll. ex retry ]
]

{ #category : #private }
PhLVirtualMachineManager >> availableVirtualMachinesIn: aFileReference [
	| vmsOnDisk |
	vmsOnDisk := Dictionary new.
	aFileReference ensureCreateDirectory.
	aFileReference directories
		reject: [ :entry | entry basename = 'private' ]
		thenDo: [ :entry | | vm |
			vm := PhLVirtualMachine directory: entry private: (aFileReference = self privateVmStore).
			vm ifValid: [ vmsOnDisk at: entry basename put: vm ] ].
	^ vmsOnDisk
]

{ #category : #private }
PhLVirtualMachineManager >> checkImageArchitecture [
	"Only warn on 64-bit Linux"
	Smalltalk os isUnix64 ifFalse: [ ^ self ]. 
	
	" Most OS are now 64-bits. Do not warn if a Pharo Launcher 32-bit tries to run a 64-bit image. "	
	(self class is64bits and: [ self class is32bits: self imageFormatNumber ])
		ifTrue: [ PhLArchitectureMismatchWarning signalLauncherArch: '64-bit' imageArch: '32-bit' ]
]

{ #category : #private }
PhLVirtualMachineManager >> compatibleVm [
	"Do not get the exact VM for the given image but only a VM able to run the image to get its version number"

	^ self availableVirtualMachinesByImageFormat
		at: self imageFormatNumber asString
		ifAbsent: [ self fetchCompatibleVm.
			self fetchSourcesFileForCompatibleVm.
			self availableVirtualMachinesByImageFormat at: self imageFormatNumber asString ]
]

{ #category : #private }
PhLVirtualMachineManager >> compatibleVmUrl [
	^ self compatibleVmUrls at: self imageFormatNumber
]

{ #category : #private }
PhLVirtualMachineManager >> compatibleVmUrls [
	| vmProvider |
	vmProvider := PhLVmProviderUntilPharo80 new.
	"50-preSpur stable is not the latest stable pre-Spur VM. 40 vm is the latest stable pre-Spur"
	^ Dictionary newFromPairs: { 
		self class imageFormat6504 . vmProvider compatibleUrlForPharo: '13' arch64: false .
		self class imageFormatPreSpur . vmProvider compatibleUrlForPharo: '40' arch64: false .
		self class imageFormat32bits . vmProvider compatibleUrlForPharo: '70' arch64: false .
		self class imageFormat64bits . vmProvider compatibleUrlForPharo: '70' arch64: true
	}
	
]

{ #category : #querying }
PhLVirtualMachineManager >> defaultVirtualMachines [

	^ { 
		(PhLVirtualMachine id: '100-x64')
			be64bits;
			yourself.
		(PhLVirtualMachine id: '90-x64')
			be64bits;
			yourself.
		(PhLVirtualMachine id: '80-x64')
			be64bits;
			yourself.
		(PhLVirtualMachine id: '80-x86')
			yourself.
	}
]

{ #category : #private }
PhLVirtualMachineManager >> fetchCompatibleVm [
	[ self class 
		fetch: self compatibleVmUrl
		to: self privateVmStore / (self imageFormatNumber asString , '.zip') ]
	on: KeyNotFound
	do: [ self error: 'No Virtual Machine available for ' , self imageFormatNumber asString, ' image format. Maybe you need to update known formats?' ]
]

{ #category : #private }
PhLVirtualMachineManager >> fetchSourcesFileForCompatibleVm [
	" We need to fetch the sources file to be able to determine the Pharo version of an image for Pharo versions < 2.0.
	Indeed, a blocking warning (about missing sources file) prevents the execution of any command line evaluation ..."
	(self imageFormatNumber = self class imageFormatPreSpur or: [ self imageFormatNumber = self class imageFormat6504 ])
		ifTrue: [ self 
			fetchSourcesFilesFor: '14' 
			in: self privateVmStore / self imageFormatNumber asString ]
]

{ #category : #private }
PhLVirtualMachineManager >> fetchSourcesFiles [
	| previousVersion |
	"Do not download sources for Pharo versions > 70 as they come along with the image."
	self imageVersion asInteger >= 70
		ifTrue: [ ^ self ].
	self fetchSourcesFilesFor: self imageVersion.
	self imageVersion = '11' 
		ifTrue: [  ^ self ]. "No support for Pharo versions < 1.1"
	"Images for alpha/beta versions (Pharo < 70) require sources for the previous version of Pharo"
	previousVersion := self imageVersion asNumber - 10.
	"But the previous version for 61 is 50, not 51"
	self imageVersion = '61'
		ifTrue: [ previousVersion := 50 ].
	"Pharo 1.0 does not exists: 2.0 => 1.4 => 1.3 => 1.2 => 1.1"
	self imageVersion = '20'
		ifTrue: [ previousVersion := 14 ].
	previousVersion < 10
		ifTrue: [ previousVersion := previousVersion + 9 ]. "bad - 10, should have done -1"
	self fetchSourcesFilesFor: previousVersion asString
]

{ #category : #private }
PhLVirtualMachineManager >> fetchSourcesFilesFor: anImageVersionString [
	| vmFolder |
	
	vmFolder := anImageVersionString asInteger < 30
		ifTrue: [ self vmStore / self vmId ]
		ifFalse: [ (self availableVirtualMachines at: self vmId) vmFolder ].
	self fetchSourcesFilesFor: anImageVersionString in: vmFolder

]

{ #category : #private }
PhLVirtualMachineManager >> fetchSourcesFilesFor: anImageVersionString in: folder [
	[ | sourcesZip |
	sourcesZip := folder / ('sourcesV' , anImageVersionString , '.zip').
	PhLDownloadManager default
		download: (self sourcesFileUrlFor: anImageVersionString)
		toFile: sourcesZip.
	self class
		unzip: sourcesZip
		to: folder ]
		on: KeyNotFound
		do: [ self error: 'No Sources file available for ' , anImageVersionString , ' image.' ]
]

{ #category : #private }
PhLVirtualMachineManager >> fetchVm [
	[ self class 
		fetch: self vmUrl 
		to: self vmStore / (self vmId , '.zip') ]
	on: KeyNotFound
	do: [ self error: 'No Virtual Machine available for ' , self imageVersion , ' image.' ]
]

{ #category : #accessing }
PhLVirtualMachineManager >> flavour [
	^ ''
]

{ #category : #accessing }
PhLVirtualMachineManager >> imageFile: anImagePathOrFileReference [
	imageFile := anImagePathOrFileReference asFileLocatorOrReference
]

{ #category : #accessing }
PhLVirtualMachineManager >> imageFormatNumber [
	^ imageFormatNumber
		ifNil: [ imageFormatNumber := self class imageFormatNumberFromFile: imageFile ]
]

{ #category : #accessing }
PhLVirtualMachineManager >> imageFormatNumber: anInteger [ 
	imageFormatNumber := anInteger
]

{ #category : #accessing }
PhLVirtualMachineManager >> imageVersion [
	"get the Pharo version of the image"

	^ imageVersion ifNil: 
		[ [ self imageVersionFromFile ]
			on: PhLImageVersionDeterminationError
			do: [ "no version file, generate it"
					[ self imageVersionFromFileWith: (self imageVersionCommandWithPreferences: false) ]
						on: PhLImageVersionDeterminationError, PhLProcessTimeOut
						do: [ "Command probably failed, try to run without --no-default-preferences option (only available since Pharo 3.0)"
								self imageVersionFromFileWith: (self imageVersionCommandWithPreferences: true) ] ] ]
]

{ #category : #accessing }
PhLVirtualMachineManager >> imageVersion: aString [ 
	imageVersion := aString
]

{ #category : #accessing }
PhLVirtualMachineManager >> imageVersionCommandWithPreferences: shouldUsePreferences [
	| process |
	process := PhLProcessWrapper new.
	process workingDirectory: self compatibleVm executableFolderPath.
	Smalltalk os isUnix
			ifTrue: [ process 
							shellCommand;
							addArguments: 'export SQUEAK_PLUGINS="" && ';
							addArgument: self compatibleVm executablePath surroundedByDoubleQuotes. ]
			ifFalse: [ process command: self compatibleVm executablePath ].
	process 
		addArgument: (Smalltalk os isUnix
			ifTrue: [ '--nodisplay' ]
			ifFalse: [ '--headless' ]);
		addArgument: imageFile fullName surroundedByDoubleQuotes.
	shouldUsePreferences ifFalse: [ process addArgument: '--no-default-preferences' ].
	process addArgument: self imageVersionDeterminationScriptPath surroundedByDoubleQuotes.
	^ process
]

{ #category : #private }
PhLVirtualMachineManager >> imageVersionDeterminationScript [
	| imageFolder |

	SystemVersion current major isNil "Pharo 1.1"
		ifTrue: [ SystemVersion current major: 1. 
					SystemVersion current minor: 1 ]. 

	(SystemVersion current major = 1 and: [ SystemVersion current minor < 4 ])
		ifTrue: [ imageFolder := (Smalltalk at: #FileDirectory) on: Smalltalk imagePath.
			imageFolder forceNewFileNamed: 'pharo.version' do: [ :stream |
				stream 
					<< SystemVersion current major;
					<< SystemVersion current minor ] ]
		ifFalse: [ imageFolder := Smalltalk imagePath asFileReference. 
			SystemVersion current major = 1
				ifFalse: [ imageFolder := imageFolder parent ].
			imageFolder / 'pharo.version' 
				writeStreamDo: [ :stream | |major minor|
					major := SystemVersion current major.
					minor := SystemVersion current minor.
					"Pharo 6 images >= 60509 need 61 VM, even though the image states 60"
					(major = 6 and: [ SystemVersion current highestUpdate >= 60509 ])
						ifTrue: [ minor := 1 ].
					stream 
						<< major asString;
						<< minor asString ] ].
	Smalltalk snapshot: false andQuit: true
]

{ #category : #private }
PhLVirtualMachineManager >> imageVersionDeterminationScriptFile [
	^ self vmStore parent / 'pharo-version.st'
]

{ #category : #private }
PhLVirtualMachineManager >> imageVersionDeterminationScriptFileNeedsUpdate [
	| file |
	file := self imageVersionDeterminationScriptFile.
	^ (file exists and: [ file contents = self imageVersionDeterminationScriptSourceCode ]) not
]

{ #category : #private }
PhLVirtualMachineManager >> imageVersionDeterminationScriptPath [
	| file |
	file := self imageVersionDeterminationScriptFile.
	self imageVersionDeterminationScriptFileNeedsUpdate
		ifTrue: [ file 
						ensureDelete;
						writeStreamDo: [ :stream | stream << self imageVersionDeterminationScriptSourceCode ] ].
	^ file fullName
]

{ #category : #private }
PhLVirtualMachineManager >> imageVersionDeterminationScriptSourceCode [
	^ (self class >> #imageVersionDeterminationScript) sourceCode
		allButFirst: #imageVersionDeterminationScript size	"remove method name"
]

{ #category : #private }
PhLVirtualMachineManager >> imageVersionFile [
	^ imageFile parent / PhLImage versionFileName
]

{ #category : #accessing }
PhLVirtualMachineManager >> imageVersionFromFile [
	self imageVersionFile 
			readStreamDo: [ :stream | imageVersion := stream contents asInteger asString ]
			ifAbsent: [ PhLImageVersionDeterminationError signal: 
				('Cannot determine image version: image version file "{1}" not found!' format: { self imageVersionFile pathString }) ].
	^ imageVersion
]

{ #category : #accessing }
PhLVirtualMachineManager >> imageVersionFromFileWith: aPhLProcessWrapperCommand [
	aPhLProcessWrapperCommand runAndWaitTimeOut: 10 seconds.
	self imageVersionFile 
			readStreamDo: [ :stream | imageVersion := stream contents asInteger asString ]
			ifAbsent: [ PhLImageVersionDeterminationError signalCommand: aPhLProcessWrapperCommand printString ].
	^ imageVersion
]

{ #category : #testing }
PhLVirtualMachineManager >> is64bit [ 
	^ self class is64bits: self imageFormatNumber 
]

{ #category : #testing }
PhLVirtualMachineManager >> isPreSpur [
	^ self class isPreSpur: self imageFormatNumber
]

{ #category : #accessing }
PhLVirtualMachineManager >> pharoVersion [
	^ self imageVersion
]

{ #category : #accessing }
PhLVirtualMachineManager >> privateVmStore [
	^ self class privateVmStore
]

{ #category : #accessing }
PhLVirtualMachineManager >> sourcesFileUrlFor: anImageVersionString [
	"$1: IMAGE_VERSION"
	^ 'https://files.pharo.org/get-files/{1}/sources.zip'
		format: {anImageVersionString}
]

{ #category : #querying }
PhLVirtualMachineManager >> virtualMachine [
	^ self virtualMachines
		detect: [ :vm | vm id = self vmId ]
		ifNone: [ PhLVirtualMachine id: self vmId ]
]

{ #category : #querying }
PhLVirtualMachineManager >> virtualMachines [
	| vmsInVmStore defaultVms |
	defaultVms := self defaultVirtualMachines.
	vmsInVmStore := self availableVirtualMachines values reject: [ :vm | defaultVms anySatisfy: [ :diskVM | diskVM id = vm id ] ].
	^ vmsInVmStore , defaultVms
]

{ #category : #querying }
PhLVirtualMachineManager >> vm [
	| vm |

	PharoLauncherApplication default 
		pushProgress: 'UNNAMED'
		with: [ :bar | 
			bar label: 'Determining Image version'.
			vm := self availableVirtualMachines 
				at: self vmId 
				ifAbsent: [
					bar 
						label: 'Fetching VM to run Pharo ', self imageVersion , ' images';
						current: 25.
					self fetchVm.
					vm := self availableVirtualMachines at: self vmId.
					bar 
						label: 'Fetching sources files for Pharo ', self imageVersion;
						current: 50.
					self fetchSourcesFiles.
					bar 
						label: 'Running the image';
						current: 100.
					vm ] ].

	^ vm executablePath
]

{ #category : #accessing }
PhLVirtualMachineManager >> vmId [
	| architecture pharoVersion |
	self checkImageArchitecture.
	architecture := self is64bit ifTrue: [ 'x64' ] ifFalse: [ 'x86' ].
	pharoVersion  := (self isPreSpur and: [ self imageVersion = '50' ])
		ifTrue: [ '50-preSpur' ]
		ifFalse: [ self imageVersion ].
	^ pharoVersion , '-' , architecture.
]

{ #category : #accessing }
PhLVirtualMachineManager >> vmStore [
	^ self class vmStore
]

{ #category : #private }
PhLVirtualMachineManager >> vmUrl [
	^ (PhLVmProvider for: self) url
]
