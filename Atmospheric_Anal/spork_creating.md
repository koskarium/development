 

Process Overview
Get your spork username and access token code.
Choose using your CAC or Fusion CA Soft Certificate for access
CAC instructions
"Getting your authentication Certificate Thumbprint."
Fusion CA Soft Certificate
"Getting a Spork Fusion Soft Cert"
"Importing Fusion CA Soft Certificate on Windows."
"Getting your authentication Certificate Thumbprint." But you find your Soft Cert's thumbprint instead of the CAC authentication Certificate.
Get Git installed.  (H drive is going away, so I'm not sure how useful this step will be with the NMCI machine lockdown.)
Configure Git.  If you get this working, most other tools inherit the settings.
Configuring GIT (Common settings.)
Configuring GIT to use a certificate from the windows certificate store on Windows.
Note:  If you are following these instructions for the internal only spork instances (such as https://spork.navsea.navy.mil/) then you only need step 1, step 3, and step 4a.

Getting your Spork account ready
Go to https://spork.fusion.navy.mil/-/user_settings/personal_access_tokens
Choose a Token name, such as "NMCI Fusion Git Token". Something so that you can identify it from the list in case you need to cancel it or know which one is expiring.
Expires: When you want it to, I usually give mine 2 years (Example below was done in May of 2022.)
In the scope section, check the “API” option.  This gives the token full control.  Other token types are useful for automation.
Andrew T Bay - Public > Configuring Git on Windows for Fusion Spork. > TokenSetup.png
Click the “Create” button.
Save the access token code immediately in a text document.  This is the only time it will show you this value.  (If you lose it, creating more is free, no need to panic.)
Note your Spork name:  Click the down arrow in the top right corner next to your avatar icon.  Under your name is @somename.  Mine is "@bayat_navsea"


Getting your Authentication Certificate Thumbprint.
Open your Start button.
Search for "Manage User Certificates"
In the Tree view, select Personal>Certificates
In the contents area on the right, find your CAC cert for Authentication.   It usually is the Last.First.Middle.Number cert with the "DOD ID CA-##" Issued by.
Double click the certificate to open it.
Find the "Thumbprint" property on the Details tab.  You can Ctrl-C copy the text after you highlight it, but you cannot right-click copy.
Andrew T Bay - Public > Configuring Git on Windows for Fusion Spork. > CertificateSample.png
Stash this somewhere for the next process.  (Empty notepad, word document, just so you have it handy.)


Getting a Spork Fusion Soft Cert
Go to https://spork.fusion.navy.mil/ca/
Click the "+Request Certificate" button.
Follow the on-screen instructions.  (Authorizations, password, download prompts.) 
Reload when complete.  It appears that you can re-download the public certificate if needed, but the private certificate is only on the first download.
Installing Portable GIT on NMCI.
(Skip this if you can install Git normally or already have it installed.)

Get the Portable Git Zip file, you may need to use https://safe.apps.mil/ to get yourself a copy from another machine. It is worthwhile to convert the self-decompressing archive into a normal zip file first.

Unzip the contents of the zip into “H:\PortableGit”  or "C:\users\[useraccount]\Local\PortableGit"

Open "Control Panel" from the start button.

Search for "Path"

Click "Edit environment variables for your account"

In the "User variables for [your name]" box, click on "Path" and then click the "Edit..." button.

In the Edit environment variable dialog, click "New" and in the blank enter "H:\PortableGit\bin" or "C:\users\[useraccount]\Local\PortableGit\bin" (match where you put it above.)

In the Edit environment variable dialog, click "New" and in the blank enter "H:\PortableGit\cmd" or "C:\users\[useraccount]\Local\PortableGit\cmd"

Click OK.  (This will allow any command window to use Git from now on.  If you are remote, remember to connect to VPN and open your H drive first.)

Configuring GIT (Common settings.)
Note: Square brackets [] indicate sections you need to replace with your personal details. Do not include the square brackets. Do include the quote marks.

Launch a command prompt
Type these commands, correcting for your information. (Copy to notepad. Remove the square brackets when updating. If you run these commands from the H drive, you will get an error, but it works from the C drive.)
C:
git config --global user.name "[Your Name]"
git config --global user.email "[Your Email Address]"
git config --global credential.helper store
git config --global credential.spork.fusion.navy.mil.provider gitlab
git config --global credential.spork-plus.fusion.navy.mil.provider gitlab
git config --global user."https://spork.fusion.navy.mil/".user "[Your Spork @ name without the @]"
git config --global user."https://spork-plus.fusion.navy.mil/".user "[Your Spork @ name without the @]"
git config --global user."https://spork.fusion.navy.mil/".password "[PutSporkAccessTokenCodeHere]"               (Skip if you are not using this spork server.)
git config --global user."https://spork-plus.fusion.navy.mil/".password "[PutSporkPlusAccessTokenCodeHere]"  (Skip if you are not using this spork server)

#This next command makes git use your windows installed certificates, IE, your DoD CA roots and your auto-registered CAC certs.
git config --global http.sslBackend schannel

#Do this if you appear to have errors related to needing a proxy:
git config --global http.proxy [steal this from IE's proxy HTTPS settings or the example below, may not be required.]

(Note: Settings such as http.[server address].property only apply to addresses that start with that string, it can go longer or shorter.  If you do http.property, that applies to all servers unless overridden by one of the more specific ones.  This also applies to the user.[server].property properties too.  You can re-run those commands for spork-plus with appropriate tweak. )

Next
If logging into a command's instance of spork, go to step 4.
if logging into the common fusion spork with your CAC, follow "Configuring GIT to use a certificate from the windows certificate store on Windows" and return to here.   
If using a certificate, follow "Importing Fusion CA Soft Certificate on Windows", "Configuring GIT to use a certificate from the windows certificate store on Windows", and return to here.
You should now be basically setup.  Test and finalize some annoying bits with the following command in the command prompt in a folder you can create folders in:
git clone https://spork.fusion.navy.mil/SandBox/DummyTest.git   (If this has been created, please?)
You should get a Pin prompt for your certificate.
Enter your spork user name if prompted for your user name (without the @ sign).

Enter your token as your password.  This will be cached for the future.  This will not display your input, so be careful to only paste it once.



Configuring GIT to use a certificate from the windows certificate store on Windows.
Note: Square brackets [] indicate sections you need to replace with your personal details.  Do not include the square brackets.  Do include the quote marks.

Note:  You will need to redo this step whenever you get a new CAC if you are using your CAC for authentication with your new authentication certificate thumbprint.  If you are using a Fusion CA soft certificate, you will need to rerun this command with the new thumbprint when you get a new one when the old one expires.

Launch a command prompt (or re-use one.)
Make sure you are not on a network drive  Type "C:" to switch to the C drive, if not already there.
#This next command makes git use a specific cert, in this case on your CAC that we found earlier.  Without this, it automatically picks one in an unpredictable way, giving you a 1 in 4+ chance of things working magically.
git config --global http."https://spork.fusion.navy.mil/".sslCert "CurrentUser\MY\[Your client certificate thumbprint]"
git config --global http."https://spork-plus.fusion.navy.mil/".sslCert "CurrentUser\MY\[Your client certificate thumbprint]"


Importing Fusion CA Soft Certificate on Windows.
We need to convert the certificate files into one that we can import into windows. Get a Fusion CA Soft Certificate from https://spork.fusion.navy.mil/ca/

Note: Square brackets [] indicate sections you need to replace with your personal details.  Do not include the square brackets.

Launch Git-Bash.  (If you did the Portable Git install correctly, just type "bash" at the command prompt.  A normal Git install, run it from the start button.)
Type the following commands:
"cd ~\Downloads"  If this command fails try "cd Downloads"  If that fails (on NMCI), copy your downloaded fusion_ files to your H drive root.
"ls fusion_*"
You should see your downloaded certificates, if you do not, you may need to ask for help at this point.  ("pwd" will display your current working directory.  Try to copy the files to that location.)
winpty openssl pkcs12 -inkey fusion_[Your DOD ID].pem -in fusion_[Your DOD ID].crt -export -out fusion_combined_[Your DOD ID].pfx
You will be prompted for your password from when you created the certificates.  Do so.  Also give the new .pfx file a password, probably the same thing.)
Back in file explorer, right click the new fusion_combined_[ID] file and choose "Install PFX".
Choose "Current User" for store location and click next.
Leave the file path alone, click next.
Enter your password from step 7.
You should check the "Enable strong private key protection." to be prompted during use.
You should not check the "Mark this key as exportable." This will protect the certificate from being exported from Windows.
Click next
Leave it automatic.  Click next.
Confirm options, Click Finish.
Use the steps in "Getting your Authentication Certificate Thumbprint." but you are looking for the certificate in the list with your DOD ID as the name from the Fusion CA.
Use the steps in "Configuring GIT to use a certificate from the windows certificate store on Windows." but you are using the thumbprint you got for the Fusion soft certificate.
Example .gitconfig for Windows
Note: Square brackets [] are part of the .gitconfig format and are required. You can replace https://spork.fusion.navy.mil/ with https://spork-plus.fusion.navy.mil for that server, you will need to make a token code on each server that you plan to use.

The value "aaA-AAAaa1A_aAaAAAaA" is the Token Code I got from "Getting your Spork Account Ready" steps above.

The value "bayat_navsea" is the user name I noted while getting my Token Code.

The value "1234567890ABCDEF1234567890ABCDEF12345678" is the cert thumbprint that I got from "Getting your Authentication Certificate Thumbprint." steps near the top of the page or your Fusion CA Soft certificate from "Importing Fusion CA Soft Certificate on Windows." steps directly above.



[user "https://spork.fusion.navy.mil/"]
    email="Andrew.T.Bay2.ctr@us.navy.mil"
    user="bayat_navsea"
    password="aaA-AAAaa1A_aAaAAAaA"

[http "https://spork.fusion.navy.mil/"]
    sslCert = CurrentUser\\MY\\1234567890ABCDEF1234567890ABCDEF12345678
    sslBackend = schannel

[url "https://spork.fusion.navy.mil/"]
  insteadOf = "git://spork.fusion.navy.mil/"


 