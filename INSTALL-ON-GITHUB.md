# Upgrading from Local Launchpad to GitHub-Backed Launchpad

You started with the airgapped (local folder) version of the launchpad. Now you want to upgrade to the full GitHub-backed version so your coach pushes improvements to a repo and you can pull updates from anywhere.

This guide walks through the conversion. **Claude can do most of this for you — just paste this whole file into a session and say "do this."**

---

## What changes

| | Local mode (now) | GitHub mode (after) |
|---|---|---|
| Master location | `C:\claude-launchpad\` (a folder on your machine) | `https://github.com/YOU/claud-app-dev-launchpad` (a GitHub repo) |
| Pull updates | Manual zip drops | `/sync-launchpad` pulls from GitHub anytime |
| Push improvements | Coach copies to local folder | Coach commits and pushes to GitHub |
| Collaboration | Only you | Anyone you give access to your repo |
| Backups | Whatever you back up locally | GitHub itself is the backup |

---

## What you need before starting

1. A free GitHub account (https://github.com/signup if you don't have one)
2. Git installed on your machine (`git --version` to check; if not, install from https://git-scm.com)
3. Your existing local master folder location (e.g. `C:\claude-launchpad\`)
4. About 10 minutes

---

## Step-by-step

### 1. Create a new empty GitHub repo

- Go to https://github.com/new
- Name it whatever you want (e.g. `my-launchpad` or `claud-app-dev-launchpad`)
- Set it to **Private** (recommended) or Public
- **Do NOT** check "Add a README" or "Add .gitignore" — leave it completely empty
- Click "Create repository"
- Copy the repo URL — it'll look like `https://github.com/YOUR_USERNAME/my-launchpad.git`

### 2. Initialize git in your master folder

Open a terminal and navigate to your master folder:

```bash
cd "C:\claude-launchpad"
```

Initialize git, add all the files, commit, and connect to your new GitHub repo:

```bash
git init
git add .
git commit -m "Initial launchpad"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/my-launchpad.git
git push -u origin main
```

If git asks you to log in, follow the prompts (GitHub will use a browser-based login the first time).

### 3. Update the .launchpad-source in each of your projects

Each of your projects has a file at `.claude/.launchpad-source` containing the local master folder path. You need to change this to the GitHub URL.

For each project:

```bash
cd "C:\path\to\your\project"
echo "https://github.com/YOUR_USERNAME/my-launchpad.git" > .claude/.launchpad-source
```

### 4. Verify

In one of your projects, run:

```bash
cat .claude/.launchpad-source
```

It should now show the GitHub URL, not the local path.

### 5. Test it

Run `/sync-launchpad --dry-run` in a project. It should clone from GitHub instead of copying from local. If it succeeds, you're done.

---

## What to do with the old local master folder

You can keep it as a backup, or delete it. The launchpad skills will no longer use it — they'll use your GitHub repo.

If you want to keep it as a fallback (e.g. for offline work), just leave it. You can switch back by changing `.launchpad-source` in a project back to the local path.

---

## What if you want to share with someone else now?

Two options:

**Option A: Give them access to your GitHub repo**
- Add them as a collaborator in your GitHub repo settings
- They clone it like you would
- Their coach pushes to your shared repo

**Option B: Have them fork your repo**
- They click "Fork" on your GitHub repo
- They clone their fork
- Their coach pushes to their fork (your repo stays untouched)
- They can periodically pull from your upstream to get your improvements

**Option C: Send them the airgapped version**
- Zip up your current launchpad files
- They run `/setup-launchpad-local` (the same airgapped flow you started with)
- Their setup is fully isolated from yours

---

## Troubleshooting

**"git push" asks for username/password:**
GitHub no longer accepts passwords for git. Use a personal access token (https://github.com/settings/tokens) or set up SSH keys (https://docs.github.com/en/authentication/connecting-to-github-with-ssh).

**Coach pushes are failing with "permission denied":**
You're trying to push to a repo you don't have write access to. Check that the URL in `.launchpad-source` is YOUR repo, not someone else's.

**`/sync-launchpad` still pulling from local folder:**
The `.launchpad-source` file might not be updated in that project. Run `cat .claude/.launchpad-source` in that project to verify.

**I want to go back to local mode:**
Change `.launchpad-source` back to your local folder path in each project. The launchpad skills will detect it's a local path and switch back.
