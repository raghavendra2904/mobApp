# Build the APK in the cloud (no Flutter needed locally)

Your PC doesn't need Flutter, Android SDK, or Java installed. GitHub will
build the APK for you on every push. You just need:

1. A web browser that can reach `github.com`
2. **Git for Windows** (small ~50 MB install) OR the **GitHub Desktop** app —
   either is fine. If even those are blocked, see the "no-Git fallback" section
   at the bottom.

---

## Step 1: Create a GitHub account

- Go to https://github.com → Sign up. Use a personal email if your work email
  domain isn't allowed.
- Verify the email.

## Step 2: Create a new repository

- Click the **+** icon (top right) → **New repository**.
- Name: `neck-alert` (or anything you like).
- Visibility: **Public** (Actions are free for public repos) or Private
  (also free, with monthly limits — plenty for this app).
- Do **NOT** tick "Add a README" — your local folder already has one.
- Click **Create repository**.

GitHub will show you a "quick setup" page with the URL of your new repo,
something like `https://github.com/your-username/neck-alert.git`. Keep that
tab open.

## Step 3: Push the `neck_alert` folder to GitHub

### Option A — using Git for Windows (command line)

Install from https://git-scm.com/download/win (just click Next on every screen).

Then open **Git Bash**, navigate to the `neck_alert` folder, and run:

```bash
cd "/c/Users/raghvendra.bhushan/Downloads/AI Projects/Mobileapps/neck_alert"

git init
git add .
git commit -m "Initial commit: Neck Alert app"
git branch -M main
git remote add origin https://github.com/YOUR-USERNAME/neck-alert.git
git push -u origin main
```

Replace `YOUR-USERNAME` with your GitHub username. The first `git push` will
ask you to sign in — use a personal access token, not your password. GitHub
walks you through that.

### Option B — using GitHub Desktop (no command line)

Install from https://desktop.github.com.

1. Open GitHub Desktop, sign in.
2. **File → Add local repository** → choose the `neck_alert` folder.
3. It will offer to create a Git repo for you — click **create a repository**.
4. Click **Publish repository** (top of the window).
5. Untick "Keep this code private" if you want a public repo, then **Publish**.

That's it. The code is on GitHub.

## Step 4: Watch the build

- Open your repo in the browser.
- Click the **Actions** tab.
- You'll see a workflow called **"Build Android APK"** running. Click into it
  to watch the steps. The first build takes ~6–8 minutes; later builds are
  faster thanks to caching.
- When it finishes (green check), scroll to the bottom of the run page.
  Under **Artifacts** you'll see two zip files:
    - `neck-alert-debug-apk` — install this for testing.
    - `neck-alert-release-apk` — smaller, faster, but unsigned.

## Step 5: Install the APK on your phone

1. Download the `neck-alert-debug-apk.zip` to your phone (or transfer from PC).
2. Unzip it → you get `app-debug.apk`.
3. On Android: open the file, allow "Install unknown apps" for your browser/
   file manager when prompted, tap Install.
4. Open Neck Alert, grant the permissions (notifications, overlay, motion).

## Re-building after code changes

Edit files locally → in Git Bash: `git add . && git commit -m "..." && git push`
(or in GitHub Desktop: write a message and click "Push origin"). GitHub
rebuilds automatically. New APK appears under Actions → latest run → Artifacts.

---

## No-Git fallback (uploading via the GitHub website)

If you cannot install Git or GitHub Desktop on your PC:

1. Create the repo on github.com as in Step 2, **but tick "Add a README"** so
   the repo has at least one file.
2. On the repo page click **Add file → Upload files**.
3. Drag-and-drop **every file and folder** from `neck_alert/` into the upload
   area. This includes the hidden `.github/` folder — on Windows Explorer
   make sure "Show hidden items" is on in the View menu.
4. Scroll down → **Commit changes**.
5. Go to the **Actions** tab. The build will start automatically.

The web uploader has a 100-file-per-upload limit, but this project has under
30 files, so it works in a single upload.

---

## Troubleshooting

**"Actions disabled for this fork/repo"** → on the Actions tab, click
"I understand my workflows, enable them".

**Build fails on `flutter create`** → usually means you didn't commit the
`pubspec.yaml`. Make sure every file under `neck_alert/` was pushed.

**Build fails on AndroidManifest** → the workflow uses
`git checkout -- android/app/src/main/AndroidManifest.xml` to restore the
custom manifest. If you renamed the file, edit the workflow.

**APK installs but app crashes immediately** → check the missing assets:
`assets/sounds/beep.mp3` is needed even if you only use the default beep tone.
Ship at least that one file.

**Need a signed release APK for Play Store** → that requires generating a
keystore and adding it as a GitHub secret. Not needed for sideloading onto
your own phone. Ask and I'll add the signing steps.
