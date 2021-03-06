SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF





-----------------------------------------------------------------------------------------
-- Procédure		: IHM_COLORIAGEGROUPE
-- Paramètre d'entrée	: @v_action : Action à mener
--			  @v_uti_id : Utilisateur
--			  @v_uti_langue : Langue
--			  @v_vue_id : Vue
--			  @v_clr_id : Règle de coloriage
--			  @v_alu_couleur : Couleur
-- Paramètre de sortie	: @v_retour : Code de retour
-- Descriptif		: Gestion des règles de coloriage par utilisateur
-----------------------------------------------------------------------------------------
-- Révision
-----------------------------------------------------------------------------------------
-- Version/ révision	: 1.00
-- Date			: 26/10/2004
-- Auteur		: Cédric LE FRINGERE
-- Libellé			: Création de la procédure
-----------------------------------------------------------------------------------------
-- Version/ révision	: 2.00
-- Date			: 08/04/2005
-- Auteur		: Cédric LE FRINGERE
-- Libellé			: Mise à jour code de retour
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[IHM_COLORIAGEGROUPE]
	@v_action smallint,
	@v_uti_id varchar(16),
	@v_uti_langue varchar(3),
	@v_vue_id int,
	@v_clr_id int,
	@v_alu_couleur int,
	@v_retour smallint out
AS

IF 1 = 0
BEGIN
	-- This line will be executed if FMTONLY was initially set to ON
	SET FMTONLY OFF
	RETURN
END

DECLARE
	@v_error int

	SELECT @v_retour = 113
	SELECT @v_error = 0
	IF (((@v_action = 0) AND NOT EXISTS (SELECT 1 FROM ASSOCIATION_COLORIAGE_UTILISATEUR, COLORIAGE WHERE ALU_UTILISATEUR = @v_uti_id
		AND CLR_ID = ALU_COLORIAGE AND CLR_TABLEAU = @v_vue_id)) OR (@v_action = 1))
	BEGIN
		IF NOT EXISTS (SELECT 1 FROM ASSOCIATION_COLORIAGE_GROUPE, ASSOCIATION_UTILISATEUR_GROUPE
			WHERE ALG_GROUPE = AUG_GROUPE AND AUG_UTILISATEUR = @v_uti_id)
			SELECT CLR_ID, 'COLORIAGE' + CONVERT(VARCHAR, CLR_ID) CLRID, LIB_LIBELLE, CLR_COULEUR COULEUR
				FROM COLORIAGE, LIBELLE WHERE CLR_TABLEAU = @v_vue_id AND LIB_TRADUCTION = CLR_TRADUCTION
				AND LIB_LANGUE = @v_uti_langue AND CLR_SQL IS NOT NULL ORDER BY CLR_ORDRE
		ELSE
			SELECT CLR_ID, 'COLORIAGE' + CONVERT(VARCHAR, CLR_ID) CLRID, LIB_LIBELLE, MIN(ALG_COULEUR) COULEUR, CLR_ORDRE
				FROM COLORIAGE, ASSOCIATION_COLORIAGE_GROUPE, ASSOCIATION_UTILISATEUR_GROUPE, LIBELLE
				WHERE CLR_TABLEAU = @v_vue_id AND ALG_COLORIAGE = CLR_ID AND ALG_GROUPE = AUG_GROUPE
				AND AUG_UTILISATEUR = @v_uti_id AND LIB_TRADUCTION = CLR_TRADUCTION AND LIB_LANGUE = @v_uti_langue
				AND CLR_SQL IS NOT NULL GROUP BY CLR_ID, LIB_LIBELLE, CLR_ORDRE
				ORDER BY CLR_ORDRE
	END
	ELSE
		SELECT CLR_ID, 'COLORIAGE' + CONVERT(VARCHAR, CLR_ID) CLRID, LIB_LIBELLE, ALU_COULEUR COULEUR
			FROM ASSOCIATION_COLORIAGE_UTILISATEUR, COLORIAGE, LIBELLE
			WHERE CLR_TABLEAU = @v_vue_id AND CLR_ID = ALU_COLORIAGE AND ALU_UTILISATEUR = @v_uti_id
			AND LIB_TRADUCTION = CLR_TRADUCTION AND LIB_LANGUE = @v_uti_langue AND CLR_SQL IS NOT NULL 
			ORDER BY CLR_ORDRE


