import AidesCore

/// `Category` existe AUSSI dans le runtime Objective-C (importé implicitement sur les plateformes
/// Apple) : sans cet alias, chaque mention de `Category` dans l'app est ambiguë. Une déclaration
/// du module courant masque les déclarations importées — c'est la façon la plus sûre de trancher.
typealias Category = AidesCore.Category
