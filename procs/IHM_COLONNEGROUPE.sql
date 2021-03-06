SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF





-----------------------------------------------------------------------------------------
-- Procédure		: IHM_COLONNEGROUPE
-- Paramètre d'entrées	: 
-- Paramètre de sorties	: 
-- Descriptif		: Gestion des colonnes des tableaux pour les groupes d un utilisateur donne
--                                        -> Recuperation des colonnes ordonnees d un tableau : ces colonnes sont stockees dans une table temporaire Tmp
--                                        -> Champs recuperes : ID_COLONNE, ORDRE, TAILLE, CLASSEMENT, SENS, LIBELLE
-----------------------------------------------------------------------------------------
-- Révision
-----------------------------------------------------------------------------------------
-- Version/ révision	: 1.00
-- Date			: 15/09/2004
-- Auteur		: Guillaume DELLOYE
-- Libellé			: Création de la procédure
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[IHM_COLONNEGROUPE]
	@v_uti_id varchar(16),
	@v_vue_id int,
	@v_uti_langue varchar(3)
AS

IF 1 = 0
BEGIN
	-- This line will be executed if FMTONLY was initially set to ON
	SET FMTONLY OFF
	RETURN
END

	BEGIN
		IF NOT EXISTS (SELECT 1 FROM ASSOCIATION_COLONNE_GROUPE, ASSOCIATION_UTILISATEUR_GROUPE 
                                                               WHERE ACG_GROUPE = AUG_GROUPE AND AUG_UTILISATEUR = @v_uti_id AND ACG_TABLEAU = @v_vue_id)
		BEGIN --Cas : pas d association vue_tableau utilisateur ni groupe => on recupere les couleurs par defaut ie directement dans vue tableau
			SELECT DISTINCT 	COL_ID as ID_COLONNE, 
						COL_ORDRE as ORDRE, 
						COL_TAILLE as TAILLE, 
						COL_CLASSEMENT as CLASSEMENT, 
						COL_SENS as SENS, 
						LIB_LIBELLE as LIBELLE
                                        FROM COLONNE, LIBELLE
				WHERE COL_TABLEAU = @v_vue_id
				      AND COL_VISIBLE = 1
                                                           -- Recuperation du libelle
                                                           AND COL_TRADUCTION = LIB_TRADUCTION
                                                           AND LIB_LANGUE = @v_uti_langue
			ORDER BY ORDRE
		END
		ELSE --Cas : un enregistrement association colonne groupe existe
		BEGIN
			SELECT DISTINCT 	ACG_COLONNE as ID_COLONNE, 
						COL_ORDRE as ORDRE, 
						COL_TAILLE as TAILLE, 
						COL_CLASSEMENT as CLASSEMENT,  
						COL_SENS as SENS, 
						LIB_LIBELLE as LIBELLE
                                        FROM ASSOCIATION_COLONNE_GROUPE, COLONNE, ASSOCIATION_UTILISATEUR_GROUPE, LIBELLE
                                                WHERE AUG_UTILISATEUR = @v_uti_id 
                                                      AND ACG_GROUPE = AUG_GROUPE
                                                      AND ACG_TABLEAU = @v_vue_id
                                                     -- Recuperation du libelle
                                                      AND COL_TABLEAU = ACG_TABLEAU
                                                      AND COL_ID = ACG_COLONNE
                                                      AND COL_TRADUCTION = LIB_TRADUCTION
                                                      AND LIB_LANGUE = @v_uti_langue
			ORDER BY ORDRE	
		END
	END




