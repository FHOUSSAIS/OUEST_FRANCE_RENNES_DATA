SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF





-----------------------------------------------------------------------------------------
-- Procédure		: IHM_VUEGROUPE
-- Paramètre d'entrées	: 
-- Paramètre de sorties	: 
-- Descriptif		: Selection des vues nom d utilisateur
--                                        On cherche les vues du un utilisateur 
--			  POURRAIT visualiser suivant le(s) 
--			  au(x)quel(s) il appartient
-----------------------------------------------------------------------------------------
-- Révision
-----------------------------------------------------------------------------------------
-- Version/ révision	: 1.00
-- Date			: 14/09/2004
-- Auteur		: Guillaume DELLOYE
-- Libellé			: Création de la procédure
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[IHM_VUEGROUPE]
	@v_uti_id varchar(16),
	@v_uti_langue varchar(3)
AS

IF 1 = 0
BEGIN
	-- This line will be executed if FMTONLY was initially set to ON
	SET FMTONLY OFF
	RETURN
END

	IF NOT EXISTS (SELECT 1 FROM ASSOCIATION_VUE_GROUPE, ASSOCIATION_UTILISATEUR_GROUPE 
                                                       WHERE AVG_GROUPE = AUG_GROUPE AND AUG_UTILISATEUR = @v_uti_id)
	BEGIN /*Cas : pas d association vue utilisateur ni groupe => on cherche les vues qu on a le droit d afficher*/
		SELECT DISTINCT VUE_ID,  LIB_LIBELLE, VUE_TYPE_VUE, VUE_ORDRE as ORDRE FROM VUE, OPERATION, ASSOCIATION_OPERATION_GROUPE, LIBELLE, ASSOCIATION_UTILISATEUR_GROUPE
			WHERE OPE_VUE = VUE_ID 
			      AND AUG_UTILISATEUR = @v_uti_id
                                                   AND AOG_GROUPE = AUG_GROUPE
                                                   AND AOG_OPERATION = OPE_ID 
		      	      AND VUE_TRADUCTION = LIB_TRADUCTION
		      	      AND LIB_LANGUE = @v_uti_langue
			      AND VUE_TYPE_VUE <> 2
			ORDER BY VUE_ORDRE
	END
	ELSE /*Cas : un enregistrement association vue groupe existe*/
		SELECT VUE_ID, LIB_LIBELLE, VUE_TYPE_VUE, MIN(AVG_ORDRE) as ORDRE FROM ASSOCIATION_VUE_GROUPE, VUE, LIBELLE, ASSOCIATION_UTILISATEUR_GROUPE
			WHERE AVG_VUE = VUE_ID
			      AND AUG_UTILISATEUR = @v_uti_id
                                                   AND AVG_GROUPE = AUG_GROUPE
		      	      AND VUE_TRADUCTION = LIB_TRADUCTION
		      	      AND LIB_LANGUE = @v_uti_langue
			GROUP BY VUE_ID, LIB_LIBELLE, VUE_TYPE_VUE
			ORDER BY MIN(AVG_ORDRE)




