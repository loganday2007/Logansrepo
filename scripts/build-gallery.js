const fs = require("fs");
const path = require("path");

const projectRoot = path.resolve(__dirname, "..");
const galleryDir = path.join(projectRoot, "gallery");
const outputFile = path.join(projectRoot, "gallery.json");

const imageExtensions = new Set([
  ".jpg",
  ".jpeg",
  ".png",
  ".gif",
  ".webp",
  ".avif",
  ".bmp",
  ".tiff",
  ".tif",
  ".svg",
]);

const isImage = (filePath) => imageExtensions.has(path.extname(filePath).toLowerCase());

const toUrlPath = (filePath) => filePath.split(path.sep).join("/");

const walkFiles = (baseDir) => {
  const entries = fs.readdirSync(baseDir, { withFileTypes: true });
  const files = [];

  entries.forEach((entry) => {
    const fullPath = path.join(baseDir, entry.name);
    if (entry.isDirectory()) {
      files.push(...walkFiles(fullPath));
      return;
    }
    if (entry.isFile() && isImage(fullPath)) {
      files.push(fullPath);
    }
  });

  return files;
};

const buildGallery = () => {
  if (!fs.existsSync(galleryDir)) {
    console.error("gallery/ folder not found.");
    return;
  }

  const topLevel = fs.readdirSync(galleryDir, { withFileTypes: true });
  const sections = [];

  topLevel.forEach((entry) => {
    if (!entry.isDirectory()) return;
    const sectionName = entry.name;
    const sectionDir = path.join(galleryDir, entry.name);
    const sectionFiles = walkFiles(sectionDir);

    const folders = new Set();
    const images = sectionFiles.map((filePath) => {
      const relativePath = path.relative(galleryDir, filePath);
      const relativeDir = path.dirname(relativePath);
      const folderName = relativeDir.split(path.sep)[0];
      if (folderName) folders.add(folderName);
      return {
        src: toUrlPath(path.join("gallery", relativePath)),
        name: path.basename(filePath),
        path: toUrlPath(relativePath),
      };
    });

    sections.push({
      name: sectionName,
      folders: Array.from(folders),
      images,
    });
  });

  const output = {
    generatedAt: new Date().toISOString(),
    sections,
  };

  fs.writeFileSync(outputFile, JSON.stringify(output, null, 2));
  console.log(`Generated ${outputFile}`);
};

buildGallery();
