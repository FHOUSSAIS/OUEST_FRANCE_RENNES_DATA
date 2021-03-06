SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF




-----------------------------------------------------------------------------------------
-- Procédure		: IHM_VUE
-- Paramètre d'entrées	: 
-- Paramètre de sorties	: 
-- Descriptif		: Gestion des vues
-----------------------------------------------------------------------------------------
-- Révision
-----------------------------------------------------------------------------------------
-- Version/ révision	: 1.00
-- Date			: 14/09/2004
-- Auteur		: Guillaume DELLOYE
-- Libellé			: Création de la procédure
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[IHM_VUE]
	@v_uti_id varchar(16),
	@v_vue_type tinyint,
	@v_uti_langue varchar(3)
AS

IF 1 = 0
BEGIN
	-- This line will be executed if FMTONLY was initially set to ON
	SET FMTONLY OFF
	RETURN
END

	IF NOT EXISTS (SELECT 1 FROM ASSOCIATION_VUE_UTILISATEUR WHERE AVU_UTILISATEUR = @v_uti_id)
	BEGIN
		IF NOT EXISTS (SELECT 1 FROM ASSOCIATION_VUE_GROUPE, ASSOCIATION_UTILISATEUR_GROUPE 
                                                               WHERE AVG_GROUPE = AUG_GROUPE AND AUG_UTILISATEUR = @v_uti_id)
		BEGIN /*Cas : pas d association vue utilisateur ni groupe => on cherche les vues qu on a le droit d afficher*/
			SELECT DISTINCT VUE_ID, VUE_TYPE_VUE, LIB_LIBELLE, VUE_ORDRE ORDRE FROM VUE, OPERATION, ASSOCIATION_OPERATION_GROUPE, LIBELLE, ASSOCIATION_UTILISATEUR_GROUPE
				WHERE OPE_VUE = VUE_ID 
				      AND AUG_UTILISATEUR = @v_uti_id
                                                           AND AOG_GROUPE = AUG_GROUPE
                                                           AND AOG_OPERATION = OPE_ID 
			      	      AND VUE_TRADUCTION = LIB_TRADUCTION
			      	      AND LIB_LANGUE = @v_uti_langue
				      AND ((@v_vue_type IS NULL AND VUE_TYPE_VUE <> 2) OR (@v_vue_type IS NOT NULL AND VUE_TYPE_VUE = @v_vue_type))
				ORDER BY VUE_ORDRE
		END
		ELSE /*Cas : un enregistrement association vue groupe existe*/
			SELECT VUE_ID, VUE_TYPE_VUE, LIB_LIBELLE, MIN(AVG_ORDRE) ORDRE FROM ASSOCIATION_VUE_GROUPE, VUE, LIBELLE, ASSOCIATION_UTILISATEUR_GROUPE
				WHERE AVG_VUE = VUE_ID
				      AND AUG_UTILISATEUR = @v_uti_id
                                                           AND AVG_GROUPE = AUG_GROUPE
			      	     AND VUE_TRADUCTION = LIB_TRADUCTION
			      	     AND LIB_LANGUE = @v_uti_langue
				      AND ((@v_vue_type IS NULL AND VUE_TYPE_VUE <> 2) OR (@v_vue_type IS NOT NULL AND VUE_TYPE_VUE = @v_vue_type))
				GROUP BY VUE_ID, VUE_TYPE_VUE, LIB_LIBELLE
				ORDER BY MIN(AVG_ORDRE)
	END
	ELSE /*Cas : un enregistrement association vue utilisateur existe*/
		SELECT VUE_ID, VUE_TYPE_VUE, LIB_LIBELLE, AVU_ORDRE ORDRE FROM ASSOCIATION_VUE_UTILISATEUR, VUE, LIBELLE
			WHERE AVU_UTILISATEUR = @v_uti_id 
                                              AND VUE_ID = AVU_VUE 
			      AND VUE_TRADUCTION = LIB_TRADUCTION
			      AND LIB_LANGUE = @v_uti_langue
				AND ((@v_vue_type IS NULL AND VUE_TYPE_VUE <> 2) OR (@v_vue_type IS NOT NULL AND VUE_TYPE_VUE = @v_vue_type))
			ORDER BY AVU_ORDRE



