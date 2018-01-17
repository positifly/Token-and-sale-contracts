#! /usr/bin/env node
var decomment = require("decomment");
const fs = require("fs");
const glob = require("glob");
const path = require("path");

//Input solidity file path
let args = process.argv.slice(2);
let inputFilePath = args[0];
//Input solidity file dir name
let inputFileDir = path.dirname(inputFilePath);
//Input parent dir
let parentDir = inputFileDir;
//Output directory to store flat combined solidity file
let outDir = args.length > 1?args[1]:"./merged";
let flatContractPrefix = args.length > 2?args[2]:path.basename(inputFilePath, ".sol");

let allSrcFiles = [];
let importedSrcFiles = {};


function removeDoubledSolidityVersion(content) {
	const subStr = "pragma solidity";
	//1st pragma solidity declaration
	let firstIndex = content.indexOf(subStr);
	let lastIndex = firstIndex + content.substr(firstIndex).indexOf(";") + 1;
	let contentPart = content.substr(lastIndex);
	let contentFiltered = contentPart;
	//remove other pragma solidity declarations
	let regex = new RegExp(subStr,"gi");
	while ( (result = regex.exec(contentPart)) ) {
		let start = result.index;
		let end = start + contentPart.substr(start).indexOf(";") + 1;
		if (start != firstIndex) contentFiltered = contentFiltered.replace(contentPart.substring(start, end), "");
	}
	let finalContent = content.substr(0, lastIndex) + contentFiltered;
	
	return finalContent;//removeTabs(finalContent);  //#10
}

function byName(dir, fileName, cb) {
	glob(dir + "/**/*.sol", function(err, srcFiles) {
		if (err) return console.log(err.message);
		
		for (var j = 0; j < srcFiles.length; j++) {
			if (path.basename(srcFiles[j]) == fileName) {
				var fileContent = fs.readFileSync(srcFiles[j], "utf8");
				cb(fileContent);
				return;
			}
		}

		dir = dir.substring(0, dir.lastIndexOf("/"));
		byName(dir, fileName, cb);
	});
}

function byNameAndReplace(dir, filePath, updatedFileContent, importStatement, cb) {
	glob(dir + "/**/*.sol", function(err, srcFiles) {
		if (err) return console.log(err.message);
		
		var importIsReplacedBefore = false;
		byNameAndReplaceInner(importStatement, updatedFileContent, dir, filePath, srcFiles, 0, cb, function() {
			if (importIsReplacedBefore) {
				updatedFileContent = updatedFileContent.replace(importStatement, "");
				cb(updatedFileContent);
			} else {
				if (dir.indexOf("/") > -1) {
					dir = dir.substring(0, dir.lastIndexOf("/"));
					byNameAndReplace(dir, filePath, updatedFileContent, importStatement, cb);
				} else {
					updatedFileContent = updatedFileContent.replace(importStatement, "");
					cb(updatedFileContent);
				}
			}
		})
	});
}

function byNameAndReplaceInner(importStatement, updatedFileContent, dir, filePath, srcFiles, j, cb, cbInner) {
	if (j >= srcFiles.length) return cbInner()
	let isAbsolutePath = filePath.indexOf(".") != 0
	if (isAbsolutePath && srcFiles[j].indexOf(filePath) > -1) {

		if (!importedSrcFiles.hasOwnProperty(path.basename(srcFiles[j]))
			|| fs.existsSync(filePath)) {
			let fileContent 
			if (fs.existsSync(filePath)) fileContent = fs.readFileSync(filePath, "utf8")
			else fileContent = fs.readFileSync(srcFiles[j], "utf8");

			findAllImportPaths(dir, fileContent, function(_importObjs) {
				fileContent = changeRelativePathToAbsolute(fileContent, srcFiles[j], _importObjs);

				if (fileContent.indexOf(" is ") > -1) {
					updatedFileContent = updatedFileContent.replace(importStatement, fileContent);
				} else {
					//updatedFileContent = updatedFileContent.replace(importStatement, fileContent);
					updatedFileContent = updatedFileContent.replace(importStatement, "");
					updatedFileContent = fileContent + updatedFileContent;
				}
				importedSrcFiles[path.basename(srcFiles[j])] = fileContent;
				return cb(updatedFileContent);
			});
		} else {
			updatedFileContent = updatedFileContent.replace(importStatement, "");
			//issue #2.
			if (updatedFileContent.indexOf(importedSrcFiles[path.basename(dir + importObj.dependencyPath)] > -1)
				&& updatedFileContent.indexOf("import ") == -1) {
				var fileContent = fs.readFileSync(srcFiles[j], "utf8");
				updatedFileContent = updatedFileContent.replace(importedSrcFiles[path.basename(dir + importObj.dependencyPath)], "");
				updatedFileContent = fileContent + updatedFileContent;
			}
			importIsReplacedBefore = true;
			j++;
			byNameAndReplaceInner(importStatement, updatedFileContent, dir, filePath, srcFiles, j, cb, cbInner)
		}
	} else {
		j++;
		byNameAndReplaceInner(importStatement, updatedFileContent, dir, filePath, srcFiles, j, cb, cbInner)
	}
}

function changeRelativePathToAbsolute(fileContent, srcFile, importObjs) {	
	//replace relative paths to absolute path for imports
	for (var i = 0; i < importObjs.length; i++) {
		let isAbsolutePath = importObjs[i].dependencyPath.indexOf(".") != 0
		if (!isAbsolutePath) {
			let _fullImportStatement = importObjs[i].fullImportStatement
			let srcFileDir = srcFile.substring(0, srcFile.lastIndexOf("/"));
			_fullImportStatement = _fullImportStatement.replace(importObjs[i].dependencyPath, srcFileDir + "/" + importObjs[i].dependencyPath)
			fileContent = fileContent.replace(importObjs[i].fullImportStatement, _fullImportStatement)
		}
	}

	return fileContent;
}

function findAllImportPaths(dir, content, cb) {
  //strip comments from content
	content = decomment(content, {safe: true})
	const subStr = "import ";
	let allImports = [];
	let regex = new RegExp(subStr,"gi");
	var importsCount = (content.match(regex) || []).length;
	let importsIterator = 0;
	while ( (result = regex.exec(content)) ) {
		let startImport = result.index;
		let endImport = startImport + content.substr(startImport).indexOf(";") + 1;
		let fullImportStatement = content.substring(startImport, endImport);
		let dependencyPath = fullImportStatement.split("\"").length > 1 ? fullImportStatement.split("\"")[1]: fullImportStatement.split("'")[1];
		let alias = fullImportStatement.split(" as ").length > 1?fullImportStatement.split(" as ")[1].split(";")[0]:null;
		let contractName;

		importObj = {
			"startIndex": startImport, 
			"endIndex": endImport, 
			"dependencyPath": dependencyPath, 
			"fullImportStatement": fullImportStatement,
			"alias": alias,
			"contractName": null
		};

		if (alias) {
			alias = alias.replace(/\s/g,'');
			var fileExists = fs.existsSync(dependencyPath, fs.F_OK);
			if (fileExists) {
				importsIterator++;
				let fileContent = fs.readFileSync(dependencyPath, "utf8");
				if (fileContent.indexOf("contract ") > -1) {
					importObj.contractName = getContractName(fileContent);
				}
				allImports.push(importObj);
			} else {
				byName(dir.substring(0, dir.lastIndexOf("/")), path.basename(dependencyPath), function(fileContent) {
					importsIterator++;
					if (fileContent.indexOf("contract ") > -1) {
						importObj.contractName = getContractName(fileContent);
					}
					allImports.push(importObj);

					if (importsIterator == importsCount) cb(allImports);
				});
			}
		} else {
			importsIterator++;
			allImports.push(importObj);
		}
	}
	if (importsIterator == importsCount) cb(allImports);
}

function getContractName(fileContent) {
	return fileContent.substring((fileContent.indexOf("contract ") + ("contract ").length), fileContent.indexOf("{")).replace(/\s/g,'')
}

function replaceAllImportsRecursively(fileContent, dir, cb) {
	let updatedFileContent = fileContent;
	findAllImportPaths(dir, updatedFileContent, function(_importObjs) {
		if (!_importObjs) return cb(updatedFileContent);
		if (_importObjs.length == 0) return cb(updatedFileContent);

		replaceAllImportsInCurrentLayer(0, _importObjs, updatedFileContent, dir, function(_updatedFileContent) {
			replaceAllImportsRecursively(_updatedFileContent, dir, cb);
		});
	});
};

function updateImportObjectLocationInTarget(importObj, content) {
	let startIndexNew = content.indexOf(importObj.fullImportStatement);
	let endIndexNew = startIndexNew - importObj.startIndex + importObj.endIndex;
	importObj.startIndex = startIndexNew;
	importObj.endIndex = endIndexNew;
	return importObj;
}

function replaceRelativeImportPaths(fileContent, curDir, cb) {
	let updatedFileContent = fileContent;
	findAllImportPaths(curDir, fileContent, function(importObjs) {
		if (!importObjs) return cb(updatedFileContent);
		if (importObjs.length == 0) return cb(updatedFileContent);

		for (let j = 0; j < importObjs.length; j++) {
			let importObj = importObjs[j];

			importObj = updateImportObjectLocationInTarget(importObj, updatedFileContent);
			let importStatement = updatedFileContent.substring(importObj.startIndex, importObj.endIndex);
			
			let newPath;
			if (importObj.dependencyPath.indexOf("../") == 0) {
				newPath = curDir + importObj.dependencyPath;
			}
			else if (importObj.dependencyPath.indexOf("./") == 0) {
				newPath = curDir + importObj.dependencyPath;
			}
			else {
				newPath = importObj.dependencyPath;
			}
			let importStatementNew = importStatement.replace(importObj.dependencyPath, newPath);
			updatedFileContent = updatedFileContent.replace(importStatement, importStatementNew);
		}
		cb(updatedFileContent);
	});
}

function replaceAllImportsInCurrentLayer(i, importObjs, updatedFileContent, dir, cb) {
	if (i < importObjs.length) {
		var importObj = importObjs[i];
		importObj = updateImportObjectLocationInTarget(importObj, updatedFileContent);

		//replace contracts aliases
		if (importObj.contractName) {
			updatedFileContent = updatedFileContent.replace(importObj.alias + ".", importObj.contractName + ".");
		}
		
		let importStatement = updatedFileContent.substring(importObj.startIndex, importObj.endIndex);

		let fileExists
		let filePath
		let isRelativePath = importObj.dependencyPath.indexOf(".") == 0
		if (isRelativePath) {
			filePath = dir + importObj.dependencyPath
			fileExists = fs.existsSync(filePath, fs.F_OK);
		}
		else {
			filePath = importObj.dependencyPath
			fileExists = fs.existsSync(filePath, fs.F_OK);
		}
		if (fileExists) {
			console.log("###" + importObj.dependencyPath + " SOURCE FILE FOUND###");
			var importedFileContent = fs.readFileSync(filePath, "utf8");

			findAllImportPaths(dir, importedFileContent, function(_importObjs) {
				importedFileContent = changeRelativePathToAbsolute(importedFileContent, filePath, _importObjs);
				replaceRelativeImportPaths(importedFileContent, path.dirname(importObj.dependencyPath) + "/", function(importedFileContentUpdated) {
					if (!importedSrcFiles.hasOwnProperty(path.basename(filePath))) {
						importedSrcFiles[path.basename(filePath)] = importedFileContentUpdated;
						if (importedFileContentUpdated.indexOf(" is ") > -1) {
							updatedFileContent = updatedFileContent.replace(importStatement, importedFileContentUpdated);
						} else {
							updatedFileContent = updatedFileContent.replace(importStatement, "");
							updatedFileContent = importedFileContentUpdated + updatedFileContent;
						}
					}
					else {
						updatedFileContent = updatedFileContent.replace(importStatement, "");
						//issue #1.
						if (updatedFileContent.indexOf(importedSrcFiles[path.basename(filePath)] > -1)
							&& updatedFileContent.indexOf("import ") == -1) {
							updatedFileContent = updatedFileContent.replace(importedSrcFiles[path.basename(filePath)], "");
							updatedFileContent = importedFileContentUpdated + updatedFileContent;
						}
					}

					i++;
					replaceAllImportsInCurrentLayer(i, importObjs, updatedFileContent, dir, cb);
				});
			})
		} else {
			if (!importedSrcFiles.hasOwnProperty(path.basename(filePath))) {
				console.log("!!!" + importObj.dependencyPath + " SOURCE FILE NOT FOUND. TRY TO FIND IT RECURSIVELY!!!");
				
				var directorySeperator;
				if (process.platform === "win32") {
					directorySeperator = "\\";
				} else {
					directorySeperator = "/";
				}
				
				byNameAndReplace(dir.substring(0, dir.lastIndexOf(directorySeperator)), importObj.dependencyPath, updatedFileContent, importStatement, function(_updatedFileContent) {
					i++;
					console.log("###" + importObj.dependencyPath + " SOURCE FILE FOUND###");
					replaceAllImportsInCurrentLayer(i, importObjs, _updatedFileContent, dir, cb);
				});
			} else {
				updatedFileContent = updatedFileContent.replace(importStatement, "");
				i++;
				replaceAllImportsInCurrentLayer(i, importObjs, updatedFileContent, dir, cb);
			}
		}
	} else cb(updatedFileContent);
}

fs.readFile(inputFilePath, "utf8", readInputFileCallBack);

function readInputFileCallBack(err, inputFileContent) {
	if (err) return console.log(err.message);

	generateFlatFile(parentDir + "/", parentDir + "/**/*.sol", inputFileContent);
}

function generateFlatFile(dir, path, inputFileContent) {
	glob(path, function(err, srcFiles) {
		allSrcFiles = srcFiles;
		if (err) return console.log(err.message);
		getAllSolFilesCallBack(inputFileContent, dir, path, srcFiles);
	});
}

function getAllSolFilesCallBack(inputFileContent, dir, path, srcFiles) {
	replaceAllImportsRecursively(inputFileContent, dir, function(outputFileContent) {
		outputFileContent = removeDoubledSolidityVersion(outputFileContent);
		if (!fs.existsSync(outDir)) fs.mkdirSync(outDir);
		fs.writeFileSync(outDir + "/" + flatContractPrefix + "_merged.sol", outputFileContent);
		console.log("Success! Flat file is generated to " + outDir + " directory");
	});
}
