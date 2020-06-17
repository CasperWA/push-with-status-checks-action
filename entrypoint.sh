#!/bin/sh

# Retrieve target repository
git clone https://${GITHUB_ACTOR}:${INPUT_GITHUB_TOKEN}@github.com/${INPUT_REPOSITORY}.git target_repo/
cd target_repo

# Setup git user
git config user.email "actions@github.com"
git config user.name "${GITHUB_ACTOR}"

if [ "${GITHUB_SHA}" != "$(git rev-parse HEAD)" ]; then
    git checkout -f "$(python -c "print('/'.join('${GITHUB_REF}'.split('/')[2:]))")"
fi

# Retrieve shell script to run changes
if [ -n "${INPUT_CHANGES}" ]; then
    wget --tries=5 https://${GITHUB_ACTOR}:${INPUT_GITHUB_TOKEN}@raw.githubusercontent.com/${GITHUB_REPOSITORY}/${GITHUB_SHA}/${INPUT_CHANGES}

    FILENAME=$(python -c "import os; print(os.path.basename('${INPUT_CHANGES}'))")
    /bin/sh ${FILENAME}
fi

# Create new temporary repository
TEMPORARY_BRANCH="push-action/${GITHUB_RUN_ID}/$(uuidgen)"
git checkout -f -b ${TEMPORARY_BRANCH}
git push -f origin ${TEMPORARY_BRANCH}

{
    # Create new temporary repository
    

    # Wait for status checks to complete
    push-action --token "${INPUT_GITHUB_TOKEN}" --repo "${INPUT_REPOSITORY}" --temp-branch "${TEMPORARY_BRANCH}" --ref "${INPUT_BRANCH}" --time-interval "${INPUT_INTERVAL}" --time-timeout "${INPUT_TIMEOUT}" wait_for_checks &&

    # Merge into target branch
    git checkout -f ${INPUT_BRANCH} &&
    git merge --ff-only origin/${TEMPORARY_BRANCH} &&
    git push origin ${INPUT_BRANCH} &&

    # Remove temporary repository
    push-action --token "${INPUT_GITHUB_TOKEN}" --repo "${INPUT_REPOSITORY}" --temp-branch "${TEMPORARY_BRANCH}" --ref "${INPUT_BRANCH}" remove_temp_branch
} || {
    # Remove temporary repository
    push-action --token "${INPUT_GITHUB_TOKEN}" --repo "${INPUT_REPOSITORY}" --temp-branch "${TEMPORARY_BRANCH}" --ref "${INPUT_BRANCH}" remove_temp_branch &&
    exit 1
}